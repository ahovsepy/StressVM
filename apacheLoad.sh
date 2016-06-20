#!/bin/bash
###############################################################################
# load apache via apache benchmark

# This script generates a desired load on apache loading the cpu 

# supported Operation Systems - Fedora/RHEL 6.x/CentOS

# Usage:
#    ./apacheLoad.sh [number of concurrent requests] [load duration] [thread count]
###############################################################################

function validate_duration_value {
      # Check if the entered duration is valid
   echo "test"
   if [[ $1 =~ ^-?[[:digit:]]+$ ]]
      then
         if [[ $2 =~ ^-?[[:digit:]]+$  ]]
            then
               if [[ $3 =~ ^-?[[:digit:]]+$ ]]
                 then
                     LOAD_DURATION=$2
                     CONCURRENCY=$1
                     THREAD_COUNT=$3
               else
                  echo "Error: Entered thread count is not a number."
                  exit
               fi
        else 
            echo "Error: Entered duration value is not a number."
            exit
        fi
   else
         echo "Error: Entered concurrency value is not a number."
   exit
   fi
}

#clean up 
function clean_up {
    #stop tomcat
    echo "cleaning up"
    pkill -9 -f tomcat
    rm -rf apache-tomcat-*

}
###############################################################################
# Start the script
###############################################################################
USAGE="Usage: `basename $0` [number of concurrent requests] [load duration] [thread count]"

   # Print usage
if [ "$1" == "-h" ] || [ "$1" == "-help" ]; then
  echo $USAGE
  exit 0
fi

# Check if there are two arguments
if [ $# -eq 3 ]; then

   # Validate input parameters.
   validate_duration_value $1 $2 $3

else
   echo "Error: the number of input arguments is incorrect!"
   echo $USAGE
   exit 1
fi


#call clean up
clean_up
#install java, unzip
sudo yum install java unzip -y

#wget apache-tomcat
wget http://www-eu.apache.org/dist/tomcat/tomcat-8/v8.0.36/bin/apache-tomcat-8.0.36.zip

#unzip tomcat
unzip  apache-tomcat-8.0.36.zip

#navigate to apache tomcat
cd apache-tomcat-8.0.36/bin/

#grand execute access to all scripts
chmod +x *.sh

#start apache tomcat server
./startup.sh &

sleep 10

#load ab
end=$((SECONDS+$LOAD_DURATION))

while [ $SECONDS -lt $end ]; do
for i in {1..$THREAD_COUNT}; do ab -c $CONCURRENCY  -t 60  localhost:8080/index.jsp ; done &
done


#load ab
#for i in {1..$THREAD_COUNT}; do ab -c $CONCURRENCY  -t $LOAD_DURATION  localhost:8080/index.jsp; done &



