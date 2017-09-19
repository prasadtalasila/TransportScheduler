#!bin/bash

################################
# Purpose: To validate the non-null nature of the Home variables
# Date: 19-Sept-2017
# Invocation: This script is invoked from load_conf.sh
# Dependencies: No dependencies
################################ 

# Alternate way to initialise Home variables

# DIRECTORY="/home/ubuntu"
# if [ -d "$DIRECTORY" ]; then
#     TS_HOME="/home/ubuntu/ts"
#     USER_HOME="/home/ubuntu"
# else
#     TS_HOME="/home/transportscheduler/project/TransportScheduler"
#     USER_HOME="home/transportscheduler"
# fi

ts_home="$( git rev-parse --show-toplevel )"
user_home="$( echo $HOME )"

SPACE=" "
echo $ts_home$SPACE$user_home 
