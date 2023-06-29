#!/bin/sh

#      Copyright (c) Microsoft Corporation.
#      Copyright (c) IBM Corporation. 
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
# 
#           http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# Deployment mode: Entitled, Unentitled or Evaluation
deploymentMode=$1
echo "The input deployment mode to be verified is ${deploymentMode}."

# Get tWAS installation properties
source /datadrive/virtualimage.properties

# Wait until entitlement/evaluation check started
while [ ! -f "$WAS_LOG_PATH" ]
do
    echo "Waiting for entitlement/evaluation check started..."
    sleep 5
done

# Wait until entitlement/evaluation check completed
isDone=false
while [ $isDone = false ]
do
    result=`(tail -n1) <$WAS_LOG_PATH`
    if [[ $result = $ENTITLED ]] || [[ $result = $UNENTITLED ]] || [[ $result = $UNDEFINED ]] || [[ $result = $EVALUATION ]]; then
        isDone=true
    else
        echo "Waiting for entitlement/evaluation check completed..."
        sleep 5
    fi
done

# Check if the entitlement/evaluation check result matches with the input deployment mode
echo "The entitlement/evaluation check result is ${result}."
if [ ${deploymentMode} != ${result} ]; then
    echo "The entitlement/evaluation check result (${result}) doesn't match with the input deployment mode (${deploymentMode})."
    exit 1
fi

# Check installation exists or not
if [ ${deploymentMode} != $UNENTITLED ]; then
    ${IHS_INSTALL_DIRECTORY}/bin/versionInfo.sh
    ${PLUGIN_INSTALL_DIRECTORY}/bin/versionInfo.sh
    ${WCT_INSTALL_DIRECTORY}/bin/versionInfo.sh
elif [ -d ${IHS_INSTALL_DIRECTORY}/bin ] || [ -d ${PLUGIN_INSTALL_DIRECTORY}/bin ] || [ -d ${WCT_INSTALL_DIRECTORY}/bin ]; then
    echo "The installation directory still exists, it should be removed for the unentitled user."
    exit 1
else
    echo "The installation is successfully removed for the unentitled user."
fi
