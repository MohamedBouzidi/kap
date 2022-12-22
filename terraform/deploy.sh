#!/bin/env bash


#########   VARIABLES  ###########

COMMANDS=("list" "install" "delete")
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PARENT_DIR=../$SCRIPT_DIR

##################################


########  FUNCTIONS   ############

display_usage() {
	echo "
	Deploy the application platform.
	Usage:
		deploy.sh [command] [options]
	
	Commands:
	-- list    : show available modules to install
	-- install : install selected module (option: module_name)
	-- delete  : delete selected module (option: module_name)
	"
}

read_command() {
	export COMMAND=$1
	shift
	export OPTIONS=$@

	if [[ " ${COMMANDS[*]} " =~ " ${COMMAND} " ]]
	then
		echo "OK"
	else
		display_usage
		exit 1
	fi
}

##################################


read_command $@
echo COMMAND is $COMMAND
echo OPTIONS are $OPTIONS
