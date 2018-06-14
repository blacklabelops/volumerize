#!/bin/sh

## 
 # @private
 # Executed if a variable is not set or is empty string
 # @param1 - Name of the failed environment variable
 ##
function _check_env_failed {
    echo "Environment variable $1 is not set."
    echo "Environment variables failed, exit 1"
    exit 1
}

## 
 # @private
 # Executed if a variable is setted
 # @param1 - Name of the environment variable
 ##
function _check_env_ok {
    echo "Env var $1 ok."
}

## 
 # Use it to check if environment variables are set
 # @param1      - Name of the context
 # @param2 to ∞ - Environment variables to check
 ##
function check_env {
    echo "Checking environment variables for $1."

    for e_var in "$@"; do
        if [ $e_var = $1 ]; then continue; fi # Jump first arg
        
        # Check if env var is setted, if not raise error
        if [ "${!e_var}" = "" ]; then 
            _check_env_failed $e_var; 
        else 
            _check_env_ok $e_var; 
        fi

    done
    echo "Environment variables ok."
}