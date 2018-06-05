#!/bin/sh

## 
 # @private
 # Executed if a variable is not set or is empty string
 # @param1 - Name of the failed environment variable
 ##
function _check_env_failed {
    echo "[!] ENV VAR $1 IS NOT SET"
    printf "\n====ENVIRONMENT VARIABLES FAILED====\n\n"
    exit 1
}

## 
 # @private
 # Executed if a variable is setted
 # @param1 - Name of the environment variable
 ##
function _check_env_ok {
    echo "Env var $1 OK"
}

## 
 # Use it to check if environment variables are set
 # @param1      - Name of the context
 # @param2 to ∞ - Environment variables to check
 ##
function check_env {
    printf "\n====CHECKING ENVIRONMENT VARIABLES FOR $1====\n\n"

    for e_var in "$@"; do
        if [ $e_var = $1 ]; then continue; fi # Jump first arg
        
        # Check if env var is setted, if not raise error
        if [ "${!e_var}" = "" ]; then 
            _check_env_failed $e_var; 
        else 
            _check_env_ok $e_var; 
        fi

    done
    printf "\n====ENVIRONMENT VARIABLES OK====\n\n"
}