#!/bin/bash
###################################################################################
#
# SH MySQL Wrapper
#
# By: Radovan Janjic
#
###################################################################################
# CONFIG
###################################################################################

# connect data
con_user="root";
con_pass="test";
con_host="localhost";
con_port="3306";
con_db="test";

# last insert id
last_insert_id=0;

# affected rows
affected_rows=0;

# log config
log_queries=1;
log_file='mysql_log.txt';

# CSV format
delimiter=',';
enclosure='"';
escape='\\';
newline='\n';
# Column names as first row
column_names=1;
# Number of ignored rows
ignore_rows=1;

# backup
backup_path='backups';

# result
num_rows=0;
num_columns=0;
# fetch return
declare -A matrix;

###################################################################################
# FUNCTION
###################################################################################

#
# mysql escape string
#
# $1 - string
escape() {
	printf -v var "%q" "$1";
	echo "$var";
}
#
## example escape string
#
#echo $(escape "'")
###################################################################################

#
# join array elements
#
# $1 - delimiter
# $2 - array
join() { 
	local IFS="$1"; shift; echo "$*"; 
}

#
## example join array
#
#join ',' "${array[@]}"
###################################################################################

#
# split string
#
# $1 - delimiter
# $2 - string
split() {
	echo $2 | tr "$1" "\n"
}

#
## example split string
#
#for x in $(split ";" "foo;bar;baz;qux"); do
#    echo "> [$x]";
#done
###################################################################################

#
# trim string
#
# $1 - string
# $2 - char to trim (default: white space)
trim() {
	if [ -z "$2" ]; then
		local char=' ';
	else
		local char=$2;
	fi
	echo "$1" | sed -e 's/^'$char'*//;s/'$char'*$//';
}

#
## example trim string
#
#echo $(trim ";foo;bar;;" ';');
###################################################################################

#
# do mysql query
#
# $1 -query
query() {
	if [ $log_queries -gt 0 ]; then
		echo `date +"%c"`" -> $1" >> $log_file;
	fi
	mysql -u$con_user -p$con_pass -h$con_host -P$con_port $con_db -e"$1";
}

#
## example query
#
#query 'describe test;'
###################################################################################

#
# query fetch first result
#
# $1 -query
fetch1st() {
	local i=0;
	local arr=();
	num_rows=0;
	num_columns=0;
	while read -r line; do
		if [ $i -gt 0 ]; then
			local j=1;
			for k in ${arr[@]}; do
				eval matrix[$k]='$(echo "$line" | cut -f$j)';
				j=`expr $j + 1`;
			done
			num_rows=$i;
		else
			local arr=(${line// / });
			for k in ${arr[@]}; do
				num_columns=`expr $num_columns + 1`;
			done
		fi
		i=`expr $i + 1`;
	done <<< "$(query "$(echo "$1" | sed -e 's/;$//;s/limit\s*[0-9]*\s*$//Ig;s/limit\s*[0-9]*\s*,\s*[0-9]*\s*$//Ig;') LIMIT 1;")"
}
#
## example fetch1st
#
#fetch1st "select * from test";
#
#echo ${matrix[id]} 
#echo ${matrix[firstname]} 
#echo ${matrix[surname]} 
#
#echo "There is "$num_rows" row and "$num_columns" columns."
###################################################################################

#
# query fetch result into array
#
# $1 -query
fetch2array() {
	num_rows=0;
	num_columns=0;
	i=0;
	while read -r line; do
		if [ $i -gt 0 ]; then
			for (( j=1; j<=num_columns; j++ )); do
				eval matrix[$i,$j]='$(echo "$line" | cut -f$j)';
			done
			num_rows=$i;
		else
			local arr=(${line// / });
			for k in ${arr[@]}; do
				num_columns=`expr $num_columns + 1`;
			done
		fi
		i=`expr $i + 1`;		
	done <<< "$(query "$1")" 
}

#
## example fetch2array
#
#fetch2array "select * from test limit 5";
#
#echo $num_rows "rows"
#echo $num_columns "cols"
#
#for (( j=1; j <= num_columns; j++ )); do
#    for (( i=1; i <= num_rows; i++ )); do
#		# $i - row
#		# $j - col
#        echo ${matrix[$i,$j]}
#    done
#done
###################################################################################

#
# insert values into table
#
# $1 - table name
# $2 - values
array2insert() {
	local i=0;
	eval "declare -A data="${2#*=};

	# prepare columns
	local columns=();
	for k in "${!data[@]}"; do
		columns+=("\`$k\`");
	done

	# prepare values
	local values=();
	for v in "${data[@]}"; do
		if [[ $v == "::"* ]]; then
			values+=(${v#"::"});
		else
			values+=("'$(escape "$v")'");
		fi
	done

	# do query
	while read -r line; do
		if [ $i -gt 0 ]; then
			last_insert_id=$(echo "$line" | cut -f1);
		fi
		i=`expr $i + 1`;
	done <<< "$(query "INSERT INTO \`$1\` ( $(join ',' "${columns[@]}") ) VALUES ( $(join ',' "${values[@]}") ); SELECT LAST_INSERT_ID();")"
}

#
## example array2insert
#
#declare -A data
#data=([id]='::null' [firstname]=Radovan [surname]=Janjic)
#array2insert 'test' "$(declare -p data)"
#echo $last_insert_id
###################################################################################

#
# update values
#
# $1 - table name
# $2 - values
# $3 - sql condition
array2update() {
	local i=0;
	local where='';

	eval "declare -A data="${2#*=};

	# prepare columns and values
	local columns=();
	for k in "${!data[@]}"; do
		if [[ ${data[$k]} == "::"* ]]; then
			columns+=("\`$k\` = "${data[$k]#"::"});
		else
			columns+=("\`$k\` = '$(escape "${data[$k]}")'");
		fi
	done

	[ -z "$3" ] || where=' WHERE '$3;

	# do query
	while read -r line; do
		if [ $i -gt 0 ]; then
			affected_rows=$(echo "$line" | cut -f1);
		fi
		i=`expr $i + 1`;
	done <<< "$(query "UPDATE \`$1\` SET $(join ',' "${columns[@]}")$where; SELECT ROW_COUNT();")" 
}

#
## example array2update
#
#declare -A data
#data=([firstname]=Rade [surname]=Janjic)
#id=3;
#array2update 'test' "$(declare -p data)" "id < $id"
#echo $affected_rows
###################################################################################

#
# export query to csv using mysql query
#
# $1 - query
# $2 - file
query2csv() {
	# real path
	local file=$(readlink -f $2);

	# remove CSV file if exists
	[ -f "$file" ] && rm $file;

	# remove ; from end of query 
	local sql=$(echo "$1" | sed "s/;$//");
	# remove ; from end of query and replace limit with limit 1 (used for column names query)
	local sqlc=$(echo "$1" | sed -e 's/;$//;s/limit\s*[0-9]*\s*$//Ig;s/limit\s*[0-9]*\s*,\s*[0-9]*\s*$//Ig;');
	# output to file sql
	local sql_out=" INTO OUTFILE '"$(escape $file)"' FIELDS TERMINATED BY '"$delimiter"' OPTIONALLY ENCLOSED BY '"$enclosure"' ESCAPED BY '"$escape"' LINES TERMINATED BY '"$newline"';";

	if [ $column_names -gt 0 ]; then
		local i=0;
		columns_sql="SELECT ";
		query "$sqlc LIMIT 1;" | while read -r line
		do
			if [ $i -lt 1 ]; then
				local arr=(${line// / });
				for i in ${arr[@]}; do
					columns_sql=$columns_sql"'"$i"' AS \`"$i"\`, ";
				done
				i=1;
				query "SELECT * FROM ( ( $(echo "$columns_sql" | sed "s/, $//") ) UNION ALL ( $sql ) ) \`a\` $sql_out";
			fi
		done
	else
		query "$sql $sql_out";
	fi
}

#
## example of query2csv
#
#query2csv 'select * from test' 'test-1.csv';
#query2csv 'select firstname,surname from test limit 2,4' 'test-2.csv';
###################################################################################

#
# export table to csv file
#
# $1 - table name
# $2 - file
table2csv(){
	query2csv "SELECT * FROM $1" $2;
}

#
## example table2csv
#
#table2csv 'test' 'test.csv'
###################################################################################

#
# import csv file to table
#
# $1 - file
# $2 - table name
# $3 - update (array) - if row fields needed to be updated eg date format or increment (SQL format only, @field is variable with content of that field in CSV row)
importcsv2table(){
	# real path
	local file=$(readlink -f $1);
	local sql="LOAD DATA LOCAL INFILE '"$(escape $file)"' INTO TABLE \`$2\` COLUMNS TERMINATED BY '"$delimiter"' OPTIONALLY ENCLOSED BY '"$enclosure"' ESCAPED BY '"$escape"' LINES TERMINATED BY '"$newline"' ";
	
	# ignore rows (eg first row is column names)
	if [ $ignore_rows -gt 0 ]; then
		sql=$sql"IGNORE "$ignore_rows" LINES";
	fi
	
	# update while importing
	if [ ! -z "$3" ]; then
		eval "declare -A update="${3#*=};
		local columns=();
		for x in $(split "$enclosure$delimiter$enclosure" "$(trim "$(head -1 $file)" '$enclosure')"); do
			if [ ! -z "${update[$x]}" ]; then
				columns+=("@$x");
			else
				columns+=("\`$x\`");
			fi
		done
		sql=$sql" ("$(join ', ' "${columns[@]}")") ";
		local ucolumns=();
		for k in "${!update[@]}"; do
			ucolumns+=("\`$k\` = ${update[$k]}");
		done
		sql=$sql"SET "$(join ', ' "${ucolumns[@]}");
	fi
	echo $sql;
	
	# do query
	i=0;
	while read -r line; do
		if [ $i -gt 0 ]; then
			affected_rows=$(echo "$line" | cut -f1);
		fi
		i=`expr $i + 1`;
	done <<< "$(query "$sql; SELECT ROW_COUNT();")" 
}

#
## example import csv file to table
#
#declare -A update
#update=([id]='NULL' [firstname]="'Radovan'");
#importcsv2table 'test.csv' 'test' "$(declare -p update)";
#echo $affected_rows;
##date format update example
##update=([date]='STR_TO_DATE(@date, "%d/%m/%Y")');
###################################################################################

#
# backup (no args will backup all databases)
#
# $1 - database name [optional]
# $2 - table name [optional]
backup() {
	local path='';
	path=$(readlink -f $backup_path);
	mkdir -p $path;
	if [ -z "$1" ] && [ -z "$2" ]; then
		mysqldump -f --opt -u$con_user -p$con_pass -h$con_host -P$con_port --all-databases > $path/`date +%Y%m%d`.sql
		gzip $path/`date +%Y%m%d`.sql
	else
		if [ ! -z "$2" ]; then
			mysqldump -f --opt -u$con_user -p$con_pass -h$con_host -P$con_port $1 $2 > $path/`date +%Y%m%d`.$1-$2.sql
			gzip $path/`date +%Y%m%d`.$1-$2.sql
		else
			mysqldump -f --opt -u$con_user -p$con_pass -h$con_host -P$con_port $1 > $path/`date +%Y%m%d`.$1.sql
			gzip $path/`date +%Y%m%d`.$1.sql
		fi
	fi
}

#
## example backup
#
#backup                        # backup all databases
#backup 'testdb'               # backup testdb
#backup 'testdb' 'test_table'  # backup test_table
###################################################################################
