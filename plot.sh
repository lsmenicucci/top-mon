CSV_FILE="mon-data.csv"
OUT="out.png"

if (($# < 2)) ; then
    echo "Usage: ./plot.sh [database.sqlite] [output.png]"
    exit 1
fi

if [[ -n "$2" ]] ; then
    OUT="$2"
fi

echo "time,name,cpu,mem,size" >> $CSV_FILE
./mon.sh $1 get | sed "s/|/\,/g" >> $CSV_FILE

vl2png plot.vl.json $OUT

rm $CSV_FILE


