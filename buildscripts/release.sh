#!/bin/bash -x

#------------------
# CONTAINER VARIABLES
#------------------
export IMAGE_VERSION=1.7.1
export BUILD_BRANCH=$(git branch | grep -e "^*" | cut -d' ' -f 2)
