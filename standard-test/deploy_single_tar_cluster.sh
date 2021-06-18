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

# This script is to automate the single cluster deployment process of OpenSearch and OpenSearch-Dashboards

set -e

# Source lib
. ../lib/shell/common.sh

ROOT=`dirname $(realpath $0)`; echo $ROOT; cd $ROOT
CURR_DIR=`pwd`
PID_PARENT_ARRAY=()

function cleanup() {
    echo
    echo "Caution: The script will attempt to completely cleanup OpenSearch/Dashboards on the server."
    echo "         It will terminate all related processes and remove temp working directories of previous runs."
    echo "         It will also terminate all the currently running nodejs processes."
    echo
    read -p "Are you sure you want to continue the cleanup? (y/n) " -r
    
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "Clean Up Now"
    else
        exit 1
    fi

    echo Kill Existing OpenSearch/Dashboards Process
    (kill -9 `ps -ef | grep -i [o]pensearch | awk '{print $2}'` > /dev/null 2>&1) || echo -e "\tClear OpenSearch Process"
    (kill -9 `ps -ef | grep -i [n]ode | awk '{print $2}'` > /dev/null 2>&1) || echo -e "\tClear Dashboards Process"

    echo Check PID List
    (ps -ef | grep -i [o]pensearch) || echo -e "\tNo OpenSearch PIDs"
    (ps -ef | grep -i [n]ode) || echo -e "\tNo Dashboards PIDs"

    echo Remove Old Deployments
    if [ -z "$TMPDIR" ]
    then
        rm -rf /tmp/*_INTEGTEST_WORKSPACE
    else
        rm -rf $TMPDIR/*_INTEGTEST_WORKSPACE
    fi
}

function usage() {
    echo ""
    echo "This script is used to deploy OpenSearch and OpenSearch-Dashboards single node cluster. It downloads the latest artifacts or specified ones per user, extract them, and deploy to the localhost to start the cluster."
    echo "--------------------------------------------------------------------------"
    echo "Usage: $0 [args]"
    echo ""
    echo "Required arguments:"
    echo -e "-v VERSION\t(1.0.0 | 1.0.0-beta1 | etc.) Specify the OpenSearch version number that you are building. This will be used to download the artifacts."
    echo -e "-t TYPE\t(snapshots | releases) Specify the OpenSearch Type of artifacts to use, snapshots or releases."
    echo -e "-s ENABLE_SECURITY\t(true | false) Specify whether you want to enable security plugin or not. Default to true."
    echo ""
    echo "Optional arguments:"
    echo -e "-c\tComplete cleanup/ whipout of the entire previous working directories and any existing OpenSearch/Dashboard/PerformanceAnalyzer processes, could also terminate other processes using nodejs, use with caution."
    echo -e "-h\tPrint this message."
    echo "--------------------------------------------------------------------------"
}


while getopts ":hct:v:s:" arg; do
    case $arg in
        v)
            VERSION=$OPTARG
            ;;
	c)
            cleanup
	    exit
	    ;;
	t)
            TYPE=$OPTARG
	    ;;
        s)
            ENABLE_SECURITY=$OPTARG
            ;;
        h)
            usage
            exit 1
            ;;
        :)
            echo -e "\nERROR: '-${OPTARG}' requires an argument"
            echo "'$0 -h' for usage details of this script"
            exit 1
            ;;
        ?)
            echo -e "\nERROR: Invalid option '-${OPTARG}'"
            echo "'$0 -h' for usage details of this script"
            exit 1
            ;;
    esac
done

# Validate the required parameters to present
if [ -z "$VERSION" ] || [ -z "$TYPE" ] || [ -z "$ENABLE_SECURITY" ]; then
    echo -e "\nERROR: You must specify '-v VERSION', '-t TYPE', '-s ENABLE_SECURITY'"
    echo "'$0 -h' for usage details of this script"
    exit 1
else
    echo VERSION:$VERSION TYPE:$TYPE ENABLE_SECURITY:$ENABLE_SECURITY
fi

# Setup Work Directory
# Trap TERM INT EXIT only since CHLD will result in workdir get deleted before
# the main OpenSearch/Dashboards process even start running
DIR=$(mktemp --suffix=_INTEGTEST_WORKSPACE -d)
echo New workspace $DIR
trap '{ echo Removing workspace in "$DIR"; rm -rf -- "$DIR"; }' TERM INT EXIT
mkdir -p $DIR/opensearch $DIR/opensearch-dashboards
cd $DIR

# Download Artifacts
echo -e "\nDownloading Artifacts Now"
OPENSEARCH_URL="https://artifacts.opensearch.org/${TYPE}/bundle/opensearch/${VERSION}/opensearch-${VERSION}-linux-x64.tar.gz"
DASHBOARDS_URL="https://artifacts.opensearch.org/${TYPE}/bundle/opensearch-dashboards/${VERSION}/opensearch-dashboards-${VERSION}-linux-x64.tar.gz"
echo -e "\t$OPENSEARCH_URL"
echo -e "\t$DASHBOARDS_URL"
curl -s -f $OPENSEARCH_URL -o opensearch.tgz || exit 1
curl -s -f $DASHBOARDS_URL -o opensearch-dashboards.tgz || exit 1
ls $DIR

# Extract Artifacts
echo -e "\nExtract Artifacts Now"
tar -xzf opensearch.tgz -C opensearch/ --strip-components=1
tar -xzf opensearch-dashboards.tgz -C opensearch-dashboards/ --strip-components=1

# Setup OpenSearch
echo -e "\nSetup OpenSearch"
cd $DIR/opensearch && mkdir -p backup_snapshots
$ROOT/opensearch-onetime-setup.sh $DIR/opensearch
sed -i /^node.max_local_storage_nodes/d ./config/opensearch.yml
# Required for IM
echo "path.repo: [\"$PWD/backup_snapshots\"]" >> config/opensearch.yml
echo "node.name: init-master" >> config/opensearch.yml
echo "cluster.initial_master_nodes: [\"init-master\"]" >> config/opensearch.yml
echo "cluster.name: opensearch-${VERSION}-linux-x64" >> config/opensearch.yml
echo "network.host: 0.0.0.0" >> config/opensearch.yml
echo "plugins.destination.host.deny_list: [\"10.0.0.0/8\", \"127.0.0.1\"]" >> config/opensearch.yml
# Required for SQL
echo "script.context.field.max_compilations_rate: 1000/1m" >> config/opensearch.yml
# Required for Security
echo "plugins.security.unsupported.restapi.allow_securityconfig_modification: true" >> config/opensearch.yml
# Required for PA
echo "webservice-bind-host = 0.0.0.0" >> plugins/opensearch-performance-analyzer/pa_config/performance-analyzer.properties
# Security setup
if [ "$ENABLE_SECURITY" == "false" ]
then
    echo -e "\tRemove OpenSearch Security"
    #./bin/opensearch-plugin remove opensearch-security
    echo "plugins.security.disabled: true" >> config/opensearch.yml
fi

# Setup Dashboards
echo -e "\nSetup Dashboards"
cd $DIR/opensearch-dashboards
echo "server.host: 0.0.0.0" >> config/opensearch_dashboards.yml
# Security Setup
if [ "$ENABLE_SECURITY" == "false" ]
then
    echo -e "\tRemove Dashboards Security"
    ./bin/opensearch-dashboards-plugin remove security-dashboards
    sed -i /^opensearch_security/d config/opensearch_dashboards.yml
    sed -i 's/https/http/' config/opensearch_dashboards.yml
fi

# Start OpenSearch
echo -e "\nStart OpenSearch, wait for 30 seconds"
cd $DIR/opensearch
./opensearch-tar-install.sh > opensearch.log 2>&1 &
PID_PARENT_ARRAY+=( $! )
sleep 30

# Start Dashboards
echo -e "\nStart Dashboards, wait for 10 seconds"
cd $DIR/opensearch-dashboards/bin
./opensearch-dashboards > opensearch-dashboards.log 2>&1 &
PID_PARENT_ARRAY+=( $! )
sleep 10

# Outputs
echo
echo Security Plugin: $ENABLE_SECURITY
echo Startup OpenSearch/Dashboards Complete
echo

set -m
trap '{ echo Removing workspace in "$@"; rm -rf -- "$@"; }' TERM INT EXIT CHLD

Trap_Wait_Term ${PID_PARENT_ARRAY[@]}



