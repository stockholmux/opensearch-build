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

function Wait_Process_PID() {
    for pid_wait in $@
    do
        wait $pid_wait
        echo "Process $pid_wait exited with code $?"
    done
}

function Kill_Process_PID() {
    for pid_kill in $@
    do
      if kill -0 $pid_kill > /dev/null 2>&1
      then
          echo "Process $pid_kill killed with code $?"
          kill -TERM $pid_killD
          wait $pid_kill
      fi

    done
}

function All_In_One() {
    set -m
    trap '{ Kill_Process_PID $@ ; }' TERM INT EXIT CHLD
    Wait_Process_PID $@
}

#function Start_Process() {
#    for process_start in $@
#    do
#        eval $process_start & 
#        echo "Process $process_start starteded with code $?"
#    done
#}


