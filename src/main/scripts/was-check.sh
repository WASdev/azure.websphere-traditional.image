#!/bin/bash

#      Copyright (c) Microsoft Corporation.
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

echo "Checking at + $(date)" > /var/log/cloud-init-was.log

# Variables
SSLPREF="com.ibm.cic.common.core.preferences.ssl.nonsecureMode=false"
DOWNLOADPREF="com.ibm.cic.common.core.preferences.preserveDownloadedArtifacts=false"
repositoryUrl=https://www.ibm.com/software/repositorymanager/entitled
wasNDTraditional=com.ibm.websphere.ND.v90_9.0.5007.20210301_1241
ibmJavaSDK=com.ibm.java.jdk.v8_8.0.6026.20210226_0840

# Read custom data from ovf-env.xml
customData=`xmllint --xpath "//*[local-name()='Environment']/*[local-name()='ProvisioningSection']/*[local-name()='LinuxProvisioningConfigurationSet']/*[local-name()='CustomData']/text()" /var/lib/waagent/ovf-env.xml`
IFS=',' read -r -a ibmIdCredentials <<< "$(echo $customData | base64 -d)"

# Check whether IBMid is entitled or not
entitled=false
if [ ${#ibmIdCredentials[@]} -eq 2 ]; then
    userName=${ibmIdCredentials[0]}
    password=${ibmIdCredentials[1]}
    
    /datadrive/IBM/InstallationManager/V1.9/eclipse/tools/imutilsc saveCredential -secureStorageFile storage_file \
        -userName "$userName" -userPassword "$password" -passportAdvantage
    if [ $? -eq 0 ]; then
        output=$(/datadrive/IBM/InstallationManager/V1.9/eclipse/tools/imcl listAvailablePackages -cPA -secureStorageFile storage_file)
        echo $output | grep -q "ND.v90_9.0.5007" && entitled=true
    else
        echo "Cannot connect to Passport Advantage." >> /var/log/cloud-init-was.log
    fi
else
    echo "Invalid input format." >> /var/log/cloud-init-was.log
fi

if [ ${entitled} = true ]; then
    # Update all packages for the entitled user
    output=$(/datadrive/IBM/InstallationManager/V1.9/eclipse/tools/imcl updateAll -repositories "$repositoryUrl" \
        -acceptLicense -log log_file -installFixes none -secureStorageFile storage_file -preferences $SSLPREF,$DOWNLOADPREF -showProgress)
    echo "$output" >> /var/log/cloud-init-was.log
    echo "Entitled" >> /var/log/cloud-init-was.log
else
    # Remove tWAS installation for the un-entitled user
    output=$(/datadrive/IBM/InstallationManager/V1.9/eclipse/tools/imcl uninstall "$wasNDTraditional" "$ibmJavaSDK" -installationDirectory /datadrive/IBM/WebSphere/ND/V9/)
    echo "$output" >> /var/log/cloud-init-was.log
    rm -rf /datadrive/IBM
    echo "Unentitled" >> /var/log/cloud-init-was.log
fi

# Scrub the custom data from files which contain sensitive information
if grep -q "CustomData" /var/lib/waagent/ovf-env.xml; then
    sed -i "s/${customData}/REDACTED/g" /var/lib/waagent/ovf-env.xml
    sed -i "s/Unhandled non-multipart (text\/x-not-multipart) userdata: 'b'.*'...'/Unhandled non-multipart (text\/x-not-multipart) userdata: 'b'REDACTED'...'/g" /var/log/cloud-init.log
    sed -i "s/Unhandled non-multipart (text\/x-not-multipart) userdata: 'b'.*'...'/Unhandled non-multipart (text\/x-not-multipart) userdata: 'b'REDACTED'...'/g" /var/log/cloud-init-output.log
fi

# Remove temporary files
rm -rf storage_file && rm -rf log_file
