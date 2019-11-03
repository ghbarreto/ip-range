#!/bin/sh

#DELETING ALL TEMP FILES

#TO RUN THIS FILE ./script [ipstart] [ipend] 
#EXAMPLE ./script 50.153.123.160 50.153.123.168 

rm -rf doc2.txt ip1.txt ip2.txt readt1.txt readt2.txt readt3.txt time.txt time2.txt readt.txt doc.txt ttl.txt ttl2.txt ttl3.txt packetsres.txt packets.txt

start_ip=$1
end_ip=$2

echo $start_ip > ip1.txt
echo $end_ip > ip2.txt

check_1=`echo $start_ip | grep -o '[^.]*$'`
check_2=`echo $end_ip | grep -o '[^.]*$'`

res_1=`sed -e 's/\.[^\.]*$//' ip1.txt`
res_2=`echo $end_ip | sed -e 's/\.[^\.]*$//' ip2.txt`

date=0

if [ "$check_1" -gt "$check_2" ]; then
    echo "The start address is bigger than the end point"
    exit 1;
fi
count_failed=0
while [ "$check_2" -ge "$check_1" ]; 
    do  
        ping -c 1 $res_1".""$check_1" > doc2.txt
        if [ $? -eq 2 ]; then
            echo $res_1"."$check_1 ": Not Reachable"
            count_failed=$(($count_failed+1))
        else
            ping -c 1 $res_1".""$check_1" | while read pong; do echo "$(date): $pong"; done >> doc.txt
            echo $res_1"."$check_1 ": Reachable"           
        fi
        check_1=$[$check_1 +1]
    done

echo `sed -n 's/\ping statistics .*//p' doc.txt > readt.txt`
echo `sed -e 's/---/ /' readt.txt > readt2.txt`

echo `sed -e 's#.*time=\(\)#\1#' -n -e  '/^[0-9]/p' doc.txt >> time.txt`
echo `sed -e '/ms/!d' -e 's/ms/ /g' time.txt > readt3.txt`


echo `sed -e 's#.*ttl=\(\)#\1#' -n -e '/^[0-9]/p' doc.txt > ttl.txt`
echo `sed -e '/time=/!d' ttl.txt > ttl2.txt`
my_ttl=(`awk '{print $1}' ttl2.txt`)


packets=$(echo `sed -e 's#.*transmitted\(\)#\1#' -e '/^[A-Z]/d' doc.txt` > packets.txt)

echo `sed -e 's/packets received*.//g' -e 's/packet loss *.//g' -e 's/,/ /g' -e 's/[0-9].[0-9]%/ /g' -e 's/[a-z]/ /g' packets.txt > packetsres.txt`
packets_results=`awk '{for(i=1;i<=NF;i++)s+=$i}END{print s}' packetsres.txt`


avg_ping=0
if [[ $(wc -l <readt3.txt) -ge 10 ]]; then 
        avg_ping="Exceeded 10 values"
    else
        avg_ping=`awk '{ total += $1; count++ } END { print total/count }' readt3.txt`
fi
echo "Info, Result" >> result.csv
while read -a LINE
    do 
        
        echo "Server Address,${LINE[6]} \nDate,${LINE[0]} ${LINE[2]} ${LINE[1]} ${LINE[3]} \n-" >> result.csv

    done < "readt2.txt"

echo "Average," $avg_ping >> result.csv
echo "First TTL," $my_ttl >> result.csv
echo "Packets Received," $packets_results >> result.csv
echo "Packet loss," $count_failed >> result.csv

# DELETING ALL TEMP FILES
rm -rf ip1.txt ip2.txt readt1.txt readt2.txt readt3.txt time.txt time2.txt readt.txt doc.txt ttl.txt ttl2.txt ttl3.txt doc2.txt packetsres.txt packets.txt

