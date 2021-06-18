#!/bin/bash

# SPDX-License-Identifier: Apache-2.0
#
# The OpenSearch Contributors require contributions made to
# this file be licensed under the Apache-2.0 license or a
# compatible open source license.
#
# Modifications Copyright OpenSearch Contributors. See
# GitHub history for details.


# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

# This is a library of all OpenSearch/Dashboards cluster related functions
# Source this file in your scripts

SIG_LIST="TERM INT EXIT CHLD"

function Wait_Process_PID() {
    for pid_wait in $@
    do
        wait $pid_wait
        echo -e "\tProcess $pid_wait confirmed exited with code $?"
    done
}

function Kill_Process_PID() {
    # Reset all the signals in case all the trap check again due to Kill_Process_PID()
    #trap - $SIG_LIST

    echo "Attempt to Terminate Process with PID: $@"
    for pid_kill in $@
    do
      echo "Check PID $pid_kill Status"
      if kill -0 $pid_kill > /dev/null 2>&1
      then
          echo -e "\tProcess $pid_kill exist, gracefully terminated with code $?"
          pkill -TERM -P $pid_kill
          Wait_Process_PID $pid_kill
      else
          echo -e "\tProcess $pid_kill not exist"
      fi

    done
}

function Trap_Cleanup_Working_Dir() {
    set -m
    trap '{ echo Removing workspace in "$@"; rm -rf -- "$@"; }' $SIG_LIST
}

function Trap_Wait_Term() {
    set -m
    echo "PID List: $@"
    echo "Trap and Wait for these signals: ${SIG_LIST}"

    trap '{ Kill_Process_PID $@ ; }' $SIT_LIST

    Trap Cleanup_Working_Dir

    Wait_Process_PID $@
}



