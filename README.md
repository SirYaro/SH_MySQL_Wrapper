SH_MySQL_Wrapper
================

SH MySQL Wrapper

`````bash
#!/bin/bash
source $(readlink -f "mysql_wrapper.sh");

#
# example escape string
#

echo $(escape "'");

#
# example query
#

query 'select * from test;';

#
# example fetch query
#

i=0;
query 'select * from test;' | while read -r line; do
	if [ $i -gt 0 ]; then
		echo ----------------------------------[ Row $i ]
		echo "Column 1: "$(echo "$line" | cut -f1) # column 1
		echo "Column 2: "$(echo "$line" | cut -f2) # column 2
		echo "Column 3: "$(echo "$line" | cut -f3) # column 3
		# column ...
	fi
	i=`expr $i + 1`;
done

#
# example fetch 1st result from query
#

fetch1st "select * from test";

echo ${matrix[id]} 
echo ${matrix[firstname]} 
echo ${matrix[surname]} 

echo "There is "$num_rows" row and "$num_columns" columns."

#
# example fetch2array
#

fetch2array "select * from test limit 5";

echo $num_rows "rows"
echo $num_columns "cols"

for (( j=1; j <= num_columns; j++ )); do
    for (( i=1; i <= num_rows; i++ )); do
		# $i - row
		# $j - col
        echo ${matrix[$i,$j]}
    done
done

#
# example array2insert
#

declare -A data
data=([id]='::null' [firstname]=Radovan [surname]=Janjic)
array2insert 'test' "$(declare -p data)"
echo $last_insert_id

#
# example array2update
#

declare -A data
data=([firstname]=Rade [surname]=Janjic)
id=3;
array2update 'test' "$(declare -p data)" "id < $id"
echo $affected_rows

#
# example of query2csv
#

query2csv 'select * from test' 'test-1.csv';
query2csv 'select firstname,surname from test limit 2,4' 'test-2.csv';

#
# example table2csv
#

table2csv 'test' 'test.csv'

#
# example importcsv2table
#

declare -A update
update=([id]='NULL' [firstname]="'Radovan'");
importcsv2table 'test.csv' 'test' "$(declare -p update)";
echo $affected_rows;
#update=([date]='STR_TO_DATE(@date, "%d/%m/%Y")');

#
# example backup
#

backup                        # backup all databases
backup 'testdb'               # backup testdb
backup 'testdb' 'test_table'  # backup test_table

`````
