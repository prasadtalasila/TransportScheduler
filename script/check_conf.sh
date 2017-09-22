#!bin/bash

################################
# Purpose: To validate the non-null nature of the Home variables
# Date: 19-Sept-2017
# Invocation: This script is invoked from load_conf.sh
# Dependencies: No dependencies
################################ 

CONFIG_FILE=./home.conf

if [ -f $CONFIG_FILE ];
then
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
fi 

if [ ! -d "$TS_HOME" ]; then
    exit 1
fi

if [ ! -d "$ASDF_HOME" ]; then
    exit 1
fi

echo "1"
