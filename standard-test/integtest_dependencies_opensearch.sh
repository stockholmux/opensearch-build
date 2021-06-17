#!/bin/bash
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
