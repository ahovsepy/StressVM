 #!/bin/bash
###############################################################################
# # CPU load script 

# This script generates a desired CPU load and forces it per each core on 
# machines running Ubuntu.

# It requires stress and cpulimit to be installed on the target machine:
#    sudo apt-get install stress cpulimit

# Usage:
#    ./cpuload.sh [cpu load in percent] [duration in seconds] [cpu count]
#    ./cpuload.sh 25 10 2
###############################################################################


###############################################################################
# Define general functions to be used by the script
###############################################################################
   
   # Validate the input arguments
function validate_cpu_load_value {
      # Check if the entered CPU load is valid
   if [[ $@ =~ ^-?[[:digit:]]+$ ]]
      then
         if [[ $@ -gt $((100)) ]] || [[ $@ -lt $((0)) ]]
            then
               echo "Error: Entered CPU load value is not valid."
               echo "Valid range 0-100%." 
               exit
            else
               CPULIMIT=$@ 
         fi
      else
         echo "Error: Entered CPU load value is not a number."
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
               CPU_LOAD_DURATION=$@ 
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

      #Set the affinity for each process to a separate core
      #Limit the CPU usage per stress process/PID
   array=(${STRESS_PIDS// / })
   echo $1
   for PID in "${array[@]}"
   do
   cpulimit_p_options="$cpulimit_p_options -p $PID"
   echo $PID
   sudo cpulimit -p $PID -l $1 &
   done
   
}



###############################################################################
# Start the script
###############################################################################
USAGE="Usage: `basename $0` [cpu load in percent] [duration in seconds] [cpu count]"

   # Print usage
if [ "$1" == "-h" ] || [ "$1" == "-help" ]; then
  echo $USAGE
  exit 0
fi

# Check if there are two arguments
if [ $# -eq 3 ]; then

   # Validate input parameters.
   validate_cpu_load_value $1
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
CPU_LOAD_DURATION_MIN=$(($CPU_LOAD_DURATION/60))

NUMBER_OF_CORES=$(grep -c processor /proc/cpuinfo)          
CURRENT_CORE_NUMBER=0  #Count starts from 0, 1, 2...

DESCRIPTION="CPU load script"

stress -c $CPU_COUNT  -t $CPU_LOAD_DURATION  & 
sleep 2
cpuLimit_for_each_pid  $1
