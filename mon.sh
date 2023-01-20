#!/bin/sh

DB_FILE="$1"
TABLE="Data"
IDX_TABLE="DataIdx"
VIEW_NAME="DataBuffer"

SERIES_SIZE=10
NUM_SERIES=1000
NUM_ROWS=$(( $SERIES_SIZE*$NUM_SERIES )) 

SQL_CREATE_COLS="time TEXT, name TEXT, cpu REAL, mem REAL"
SQL_INSERT_COLS="time, name, cpu, mem"

fetch(){
    date=$(date -Iseconds)
    awk_fmt="(\\\"${date}\\\", \\\"%s\\\", %s, %s),"
    top -b -n 1 | sed 1,7d | head -n $SERIES_SIZE | awk "{ printf \"${awk_fmt}\", \$12,\$9,\$10; }" | sed 's/.$//g'
}

if [[ $2 == "init" ]] ; then
    sqlite3 $DB_FILE "CREATE TABLE ${TABLE} (${SQL_CREATE_COLS})"
    sqlite3 $DB_FILE "CREATE TABLE ${IDX_TABLE} (I)"
    
    sqlite3 $DB_FILE "CREATE VIEW ${VIEW_NAME} AS
                        SELECT * FROM ${TABLE}, ${IDX_TABLE} WHERE ${TABLE}.rowID>I
                        UNION ALL
                        SELECT * FROM ${TABLE}, ${IDX_TABLE} WHERE ${TABLE}.rowID<=I;"
    

    sqlite3 $DB_FILE "CREATE TRIGGER RotateIdx BEFORE INSERT ON ${TABLE} 
                        FOR EACH ROW BEGIN 
                            UPDATE ${IDX_TABLE} SET I = ( (SELECT I FROM ${IDX_TABLE}) + 1) % ${NUM_ROWS};
                        END;"

    sqlite3 $DB_FILE "CREATE TRIGGER NewValue INSTEAD OF INSERT ON ${VIEW_NAME}
                        FOR EACH ROW BEGIN    
                            INSERT OR REPLACE INTO ${TABLE} 
                                (rowID, time, name, cpu, mem) Values ((SELECT I FROM ${IDX_TABLE}), NEW.time, NEW.name, NEW.cpu, NEW.mem);
                        END;"
    
    sqlite3 $DB_FILE "INSERT INTO ${IDX_TABLE} (I) VALUES (0)"
fi

if [[ $2 == "record" ]] ; then
    sqlite3 $DB_FILE "INSERT OR REPLACE INTO ${VIEW_NAME} (time, name, cpu, mem) VALUES $(fetch);"
fi

if [[ $2 == "get" ]] ; then
    sqlite3 $DB_FILE "SELECT * FROM ${VIEW_NAME};"
fi

if [[ $2 == "get-timestamps" ]] ; then
    sqlite3 $DB_FILE "SELECT DISTINCT time FROM ${VIEW_NAME};"
fi

