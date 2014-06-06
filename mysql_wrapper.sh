#!/bin/bash

#
# SH MySQL Wrapper
#
# By: Radovan Janjic
#

# connect data
con_user="root";
con_pass="test";
con_host="localhost";
con_port="3306";
con_db="test";

# last insert id
last_insert_id=0;

# log config
log_queries=1;
log_file='mysql_log.txt';


#
# mysql escape string
#
# $1 - string
escape() {
	printf -v var "%q" "$1";
	echo "$var";
}

#echo $(escape "'")


#
# do mysql query
#
# $1 -query
query() {
	if [ $log_queries -gt 0 ]; then
		echo "$1" >> $log_file;
	fi
	mysql -u$con_user -p$con_pass -h$con_host -P$con_port $con_db -e"$1";
}

#query 'describe test;'


#
# export query to csv using mysql query
#
# $1 - query
# $2 - file
query2csv() {
	# CSV format
	local delimiter=',';
	local enclosure='"';
	local escape='\';
	local newline='\n';
	
	# Column names as first row
	local column_names=1;
	
	# real path
	local file=$(readlink -f $2);
	
	# remove CSV file if exists
	[ -f "$file" ] && rm $file;
	
	# remove ; from end of query
	local sql=$(echo "$1" | sed "s/;$//");
	
	# TODO: replace limit with limit 1 for colectiong column names
	# /limit[\s]+([\d]+[\s]*,[\s]*[\d]+[\s]*|[\d]+[\s]*)$/i
	
	local sql_out=" INTO OUTFILE '"$(escape $file)"' FIELDS TERMINATED BY '"$delimiter"' OPTIONALLY ENCLOSED BY '"$enclosure"' ESCAPED BY '"$(escape "$escape")"' LINES TERMINATED BY '"$newline"';";
	
	if [ $column_names -gt 0 ]; then
		local i=0;
		columns_sql="SELECT ";
		query "$sql LIMIT 1;" | while read -r line
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

#mysqlquery2csv 'select * from test' 'test.csv'


#
# export table to csv file
#
# $1 - table name
# $2 - file
exporttable2csv(){
	mysqlquery2csv "SELECT * FROM $1" $2;
}

#exporttable2csv 'test' 'test.csv'


#
# insert values into table
#
# $1 - table name
# $2 - values
insertquery() {
	i=0;
	query "INSERT INTO \`$1\` VALUES ( $2 ); SELECT LAST_INSERT_ID();" | while read -r line; do
		if [ $i -gt 0 ]; then
			last_insert_id=$(echo "$line" | cut -f1);
		fi
		i=`expr $i + 1`
	done
}

#insertquery 'test' 'NULL, 1, 2, 3, NOW()'
#echo $last_insert_id

