#!bin/bash

###################################
# Purpose: Call check_conf.sh and store Home variables in home.conf
# Date: 19-Sept-2017
# Invocation: This script has to be run independently.
# Command-line options: '-f' -> will force values on home variables
#								and store them in $HOME/.bashrc
# Dependencies: check_conf.sh, home.conf
###################################

CONFIG_FILE=./script/home.conf

if [ -f $CONFIG_FILE ];
then
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
fi

# For the command-line option '-f'.
# This will force the values on the variables
# and store them in $HOME/.bashrc
while getopts ":f" opt; do
	case ${opt} in
		f ) echo "export TS_HOME=$( git rev-parse --show-toplevel )" >> "$HOME/.bashrc"
			echo "export ASDF_HOME=$HOME" >> "$HOME/.bashrc"
      source "$HOME/.bashrc"
			# Exit in case '-f' is used
			exit 0
			;;
		\? ) echo "Invalid option."
			# Exit in case some other option is used
			exit 1
			;;
	esac
done

# If the directories mentioned by user exist,
# then write to $HOME/.bashrc
bash ./script/check_conf.sh
status=$?
if [ "$status" ]; then
	echo "export TS_HOME=$TS_HOME" >> "$HOME/.bashrc"
	echo "export ASDF_HOME=$ASDF_HOME" >> "$HOME/.bashrc"
  source "$HOME/.bashrc"
fi
