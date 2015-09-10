 #!/bin/bash
###############################################################################
# # Memory load script 

# This script generates a desired CPU load and forces it per each core on 
# machines running Fedora/RHEL 6.x

# CPU load limit is hardcoded to 10%

# It requires stress and cpulimit to be installed on the target machine:
#    sudo yum install cpuload stress

# Usage:
#    ./memoryload.sh [memory load in decimal (for percent) or value] [duration in seconds] [cpu count] 
#    ./memoryload.sh 0.5 10 2 // 50%
#    ./memoryload.sh 1234 10 2 //1234k
###############################################################################


###############################################################################
# Define general functions to be used by the script
###############################################################################
      
# Validate the input arguments
function validate_memory_load_value {
 # Check if the entered memory load is valid
    if [[ $@ =~ ^-?[[:digit:]]+$ ]]
           then 
            MEMORY_RATE_PERCENT=false
            MEMORY_LIMIT=$@

    elif [[ "$@" =~ ^[0-9]+(\.[0-9]+)?$ ]]
      then
         if [[ $@ > 1 ]] || [[ $@ < 0 ]]
            then
               echo "Error: Entered memory load value is not valid."
               echo "Valid range 0.1-0.9" 
               exit
            else
               MEMORY_LIMIT=$@ 
	       MEMORY_RATE_PERCENT=true
         fi
      
      else
         echo "Error: Entered memory load value is not a number."
         exit

   fi
}

function validate_duration_value {
      # Check if the entered duration is valid
   if [[ $@ =~ ^-?[[:digit:]]+$ ]]
      then
         if [[ $@ -lt $((0)) ]]
            then
               echo "Error: Entered duration value is not valid."
               echo "The value must be greater than 0." 
               exit
            else
               LOAD_DURATION=$@ 
         fi
      else
         echo "Error: Entered duration value is not a number."
         exit
   fi
}

function validate_cpu_count_value {
 #Check if entered cpu count is valid
   if [[ $@ =~ ^-?[[:digit:]]+$ ]]
      then
         if [[ $@ -lt $((0)) ]]
            then
               echo "Error: Entered cpu count value is not valid."
               echo "The value must be greater than 0." 
               exit
            else
               CPU_COUNT=$@
         fi
      else
         echo "Error: Entered cpu count value is not a number."
        exit
  fi
}



function cpuLimit_for_each_pid {
#Retrieve all the stress process PIDS and omit the last PID of the parent process 
   echo $@
   OMIT_PID=$(pidof stress | sed 's/^.* //')
   STRESS_PIDS=$(pidof stress -o $OMIT_PID)

   # last stress PID has been removed: $STRESS_PIDS." | tee -a $FILE

      #Set the affinity for eac#h process to a separate core
      #Limit the CPU usage per stress process/PID
   array=(${STRESS_PIDS// / })
   echo $1
   for PID in "${array[@]}"
   do
   cpulimit_p_options="$cpulimit_p_options -p $PID"
   echo $PID
   sudo cpulimit -p $PID -l 10 &
   done
   
}




###############################################################################
# Start the script
###############################################################################
USAGE="Usage: `basename $0` [memory load in decimal (for percent) or value] [duration in seconds] [cpu count]"

   # Print usage
if [ "$1" == "-h" ] || [ "$1" == "-help" ]; then
  echo $USAGE
  exit 0
fi

# Check if there are two arguments
if [ $# -eq 3 ]; then

   # Validate input parameters.
   validate_memory_load_value $1
   validate_duration_value $2
   validate_cpu_count_value $3

else
   echo "Error: the number of input arguments is incorrect!"
   echo $USAGE
   exit 1
fi

# Clean the terminal screen and sudo
#clear
# Set the required parameters
LOAD_DURATION_MIN=$(($LOAD_DURATION/60))

NUMBER_OF_CORES=$(grep -c processor /proc/cpuinfo)          
CURRENT_CORE_NUMBER=0  #Count starts from 0, 1, 2...

DESCRIPTION="Memory load script"
echo $LOAD_DURATION
echo $MEMORY_LIMIT
echo $CPU_COUNT
MAX_FREE_MEMORY=$(awk '/MemFree/{printf "%d\n", $2 * 0.9;}' < /proc/meminfo)
echo "MAXFREEMEMORY" $MAX_FREE_MEMORY
echo "MEMORY_LIMIT" $MEMORY_LIMIT

if [[ $MEMORY_RATE_PERCENT == true ]]
    then 
    stress -t $LOAD_DURATION  --vm-bytes $(awk '/MemFree/{printf "%d\n", $2 * '$MEMORY_LIMIT';}' < /proc/meminfo)k --vm-keep -m $CPU_COUNT  &
    elif [[ $MAX_FREE_MEMORY  -gt  $MEMORY_LIMIT ]] 
       then 
          stress -t $LOAD_DURATION  --vm-bytes $(echo $MEMORY_LIMIT)k --vm-keep -m $CPU_COUNT  &
else
    echo "Entered memory size is bigger then the possible maximum memory size."
    exit 
fi
sleep 2
cpuLimit_for_each_pid  $1
