#!/bin/bash

# NOTE: \033 is better then \e

#export NORMAL="\e\033[00m"
#export BOLD_BLACK="\e\033[01;31m"
#export BOLD_RED="\e\033[01;31m"
#export BOLD_GREEN="\e\033[01;32m"
#export BOLD_YELLOW="\e\033[01;33m"
#export BOLD_BLUE="\e\033[01;34m"
#export BOLD_MAGENTA="\e[\033[01;35m"
#export BOLD_CYAN="\e\033[01;36m"
#export WHITE="\e\033[1;37m"

export NORMAL=$'\001\033[00m\002'
export BOLD_BLACK=$'\001\033[01;31m\002'
export BOLD_RED=$'\001\033[01;31m\002'
export BOLD_GREEN=$'\001\033[01;32m\002'
export BOLD_YELLOW=$'\001\033[01;33m\002'
export BOLD_BLUE=$'\001\033[01;34m\002'
export BOLD_MAGENTA=$'\001\033[01;35m\002'
export BOLD_CYAN=$'\001\033[01;36m\002'
export WHITE=$'\001\033[01;37m\002'
