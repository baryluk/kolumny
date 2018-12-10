#!/bin/sh

KOLUMNY=../kolumny

N=1000000

export TIME="elapsed: %e seconds, data+stack+text: %K KiBavg, text:%XKiBavg, data:%DKiBavg, rss:%tKiBavg, rss:%MKiBmax, stack:%pKiBavg"

echo "Generating simplest data file with $N records..."
time seq $N > big_input0.txt
echo
wc -l big_input0.txt
echo


echo "Generating and piping on the fly $N records..."
time seq $N | ${KOLUMNY} --import random "-" u ~x:=1 ":x" ":random.random()" ":random.randint(1, 100)" ":x*6" | ${KOLUMNY} "-" u x:=1,y:=2...4 ":2*x" ":~z:=sum(y)" ":z" > /dev/null
echo


echo "Generating more complex data file with $N records..."
time seq $N | ${KOLUMNY} --import random "-" u ~x:=1 ":x" ":random.random()" ":random.randint(1, 100)" ":x*6" > big_input1.txt
echo
wc -l big_input1.txt
echo


echo "Simplest benchmark from the file ($N records)..."
time ${KOLUMNY} "big_input0.txt" u 1 > /dev/null
echo

echo "Simple benchmark from the file ($N records)..."
time ${KOLUMNY} "big_input1.txt" u 2 > /dev/null
echo

echo "Complex benchmark from the file ($N records)..."
time ${KOLUMNY} "big_input1.txt" u x:=1,y:=2...4 ":2*x" ":~z:=sum(y)" ":z" > /dev/null
echo
