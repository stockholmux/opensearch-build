#!/bin/bash

. ../lib/shell/common.sh

TESTARR=()

sleep 5 &
TESTARR+=( $! )

sleep 10 &
TESTARR+=( $! )

#echo ${TESTARR[@]}
All_In_One ${TESTARR[@]}

#ps -ef | grep sleep
