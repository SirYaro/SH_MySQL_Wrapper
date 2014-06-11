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
		echo "$line" | cut -f1; # column 1
		echo "$line" | cut -f2; # column 2
		echo "$line" | cut -f3; # column 3
		# column ...
	fi
	i=`expr $i + 1`;
done

#
# example fetch 1st result from query
#

fetch1st "select * from test";

echo $num_rows "rows"
echo $num_columns "cols"

echo ${matrix[column_one]} 
echo ${matrix[column_two]} 


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
data=([id]='::null()' [firstname]=Radovan [surname]=Janjic)
array2insert 'test' "$(declare -p data)"
echo $last_insert_id

#
# example array2update
#

declare -A data
data=([id]='::null()' [firstname]=Radovan [surname]=Janjic)
id=1;
array2update 'test' "$(declare -p data)" "id = $id"
echo $affected_rows

#
# example of query2csv
#

query2csv 'select * from test' 'test.csv';
query2csv 'select * from test limit 20,10' 'test.csv';

#
# example table2csv
#

table2csv 'test' 'test.csv'

#
# example backup
#

backup                        # backup all databases
backup 'testdb'               # backup testdb
backup 'testdb' 'test_table'  # backup test_table
