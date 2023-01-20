CSV_FILE="mon-data.csv"
OUT="out.png"

if [[ -n "$1" ]] ; then
    OUT="$1"
fi

echo "time,name,cpu,mem,size" >> $CSV_FILE
./mon.sh get | sed "s/|/\,/g" >> $CSV_FILE

vl2png plot.vl.json $OUT

rm $CSV_FILE


