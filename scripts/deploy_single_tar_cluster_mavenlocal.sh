#!/bin/bash
# This is a temporary measure before we have maven central setup
# Assume this script is in the root directory of OpenSearch repository
# https://github.com/opensearch-project/OpenSearch
# $1 is the version qualifier such as beta1, rc1

./gradlew publishToMavenLocal -Dbuild.version_qualifier=$1 -Dbuild.snapshot=false --console=plain
