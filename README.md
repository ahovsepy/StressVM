see cpuLoad parent script under ajurge/CPU_load repository

It requires *stress* and *cpulimit* to be installed on the target machine:

	- sudo apt-get install stress cpulimit (ubuntu)
	- sudo yum install stress cpulimit (fedora/rhel)

# CPU load script 

This script generates a desired CPU load and forces it per each core on 
machines running Unix.

Usage: 

	- ./cpuload.sh [cpu load in percent] [duration in seconds] [cpu count]
	- ./cpuload.sh 25 10 2 
	- ./cpuload.sh unlimited 10 2 

# Memory load script 

This script generates a desired memory load and forces it per each core on
machines running Unix.

Usage:

	- ./memoryload.sh [memory load in decimal (for percent) or value] [duration in seconds] [cpu count] 
	- ./memoryload.sh 0.5 10 2  //will load till 50%
	- ./memoryload.sh 1234 10 2 //will load exactly 1234k


