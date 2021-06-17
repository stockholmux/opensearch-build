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

# This is a temporary measure before we have maven central setup
# Assume this script is in the root directory of OpenSearch repository
# https://github.com/opensearch-project/OpenSearch
# $1 is the local repo that needs deployment
# $2 is the version number such as 1.0.0, 2.0.0
# $3 is the version qualifier such as beta1, rc1

if [ "$1" == "maven" ]
then
  ./gradlew publishToMavenLocal -Dbuild.version_qualifier=$2 -Dbuild.snapshot=false --console=plain
elif [ "$1" == "cu" ]
then
  ./gradlew publishToMavenLocal -Dopensearch.version=$2-$3 --console=plain
elif [ "$1" == "js" ]
  ./gradlew publishToMavenLocal -Dopensearch.version=$2-$3 -Dbuild.snapshot=false --console=plain
fi
