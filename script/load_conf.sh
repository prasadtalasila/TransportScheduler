#!bin/bash

###################################
# Purpose: Call check_conf.sh and store Home variables in home.conf
# Date: 19-Sept-2017
# Invocation: This script has to be run independently and the 
#  			  home variables are then stored in home.conf.
# 			  These are then used in the other scripts in the folder.
# Dependencies: check_conf.sh
###################################

# Iterate through the output of check_conf.sh
# and store the individual values in TS_HOME and USER_HOME. 
conf="$( sh check_conf.sh )"
i=0
for word in $conf
do
	if [ "$i" -eq "0" ]; then
		TS_HOME=$word
	else
		USER_HOME=$word
	fi
	i=$((i+1))
done

# Display values of TS_HOME and USER_HOME
echo "Home of project: "$TS_HOME""
echo "Home of user: "$USER_HOME""

# Overwrite contents of home.conf or create a file if not present
> home.conf

# Write into the config file
echo "TS_HOME="$TS_HOME"" >> home.conf
echo "USER_HOME="$USER_HOME"" >> home.conf