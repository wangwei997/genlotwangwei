#!/bin/sh
if [ $# -lt 1 ] ; then 
    echo "usage: restart_server.sh </path/shell>" 
    exit 1; 
fi

shell=$1
untilSec=${2:-45}
printf "`date +"[%F %T]"` reload $shell at $untilSec\n"
if [ -x "$shell" ]; then 
     while true
     do
         second=`date +"%S"`
         if [ "$second" == "$untilSec" ]; then
             printf "\n`date +"[%F %T]"` execute $shell\n\n"
             printf "================= output =================\n"
             $shell
             # /usr/local/bin/update.web.sh
             printf "\n==========================================\n\n"
             printf "`date +"[%F %T]"` done!\n"
             break
         else
             printf "\r`date +"[%F %T]"` waiting... %s" $second
             sleep 1
         fi
     done
else
    printf "`date +"[%F %T]"` '$shell' is not a executable shell\n"
fi

