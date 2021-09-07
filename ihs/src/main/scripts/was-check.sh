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

# Get tWAS installation properties
source /datadrive/virtualimage.properties

echo "$(date): Start to check entitlement." > $WAS_LOG_PATH

# Read custom data from ovf-env.xml
customData=`xmllint --xpath "//*[local-name()='Environment']/*[local-name()='ProvisioningSection']/*[local-name()='LinuxProvisioningConfigurationSet']/*[local-name()='CustomData']/text()" /var/lib/waagent/ovf-env.xml`
read -r -a ibmIdCredentials <<< "$(echo $customData | base64 -d)"

# Check whether IBMid is entitled or not
result=$UNENTITLED
if [ ${#ibmIdCredentials[@]} -eq 2 ]; then
    userName=${ibmIdCredentials[0]}
    password=${ibmIdCredentials[1]}
    
    ${IM_INSTALL_DIRECTORY}/eclipse/tools/imutilsc saveCredential -secureStorageFile storage_file \
        -userName "$userName" -userPassword "$password" -passportAdvantage
    if [ $? -ne 0 ]; then
        echo "Cannot connect to Passport Advantage while saving the credential to the secure storage file." >> $WAS_LOG_PATH
    fi
    
    output=$(${IM_INSTALL_DIRECTORY}/eclipse/tools/imcl listAvailablePackages -cPA -secureStorageFile storage_file)
    echo $output | grep -q "$WAS_ND_VERSION_ENTITLED" && result=$ENTITLED
    echo $output | grep -q "$NO_PACKAGES_FOUND" && result=$UNDEFINED
else
    echo "Invalid input format." >> $WAS_LOG_PATH
fi

echo "$(date): Entitlement check completed, start to update WebSphere installation." >> $WAS_LOG_PATH
if [ ${result} = $ENTITLED ]; then
    # Update all packages for the entitled user
    output=$(${IM_INSTALL_DIRECTORY}/eclipse/tools/imcl updateAll -repositories "$REPOSITORY_URL" \
        -acceptLicense -log log_file -installFixes recommended -secureStorageFile storage_file -preferences $SSL_PREF,$DOWNLOAD_PREF -showProgress)
    echo "$output" >> $WAS_LOG_PATH
else
    # Remove installations for the un-entitled or undefined user
    output=$(${IM_INSTALL_DIRECTORY}/eclipse/tools/imcl uninstall "$IBM_HTTP_SERVER" "$IBM_JAVA_SDK" -installationDirectory ${IHS_INSTALL_DIRECTORY})
    echo "$output" >> $WAS_LOG_PATH
    output=$(${IM_INSTALL_DIRECTORY}/eclipse/tools/imcl uninstall "$WEBSPHERE_PLUGIN" "$IBM_JAVA_SDK" -installationDirectory ${PLUGIN_INSTALL_DIRECTORY})
    echo "$output" >> $WAS_LOG_PATH
    output=$(${IM_INSTALL_DIRECTORY}/eclipse/tools/imcl uninstall "$WEBSPHERE_WCT" "$IBM_JAVA_SDK" -installationDirectory ${WCT_INSTALL_DIRECTORY})
    echo "$output" >> $WAS_LOG_PATH
    rm -rf /datadrive/IBM && rm -rf /datadrive/virtualimage.properties
fi
echo "$(date): WebSphere installation updated." >> $WAS_LOG_PATH
echo ${result} >> $WAS_LOG_PATH

# Scrub the custom data from files which contain sensitive information
if grep -q "CustomData" /var/lib/waagent/ovf-env.xml; then
    sed -i "s/${customData}/REDACTED/g" /var/lib/waagent/ovf-env.xml
    sed -i "s/Unhandled non-multipart (text\/x-not-multipart) userdata: 'b'.*'...'/Unhandled non-multipart (text\/x-not-multipart) userdata: 'b'REDACTED'...'/g" /var/log/cloud-init.log
    sed -i "s/Unhandled non-multipart (text\/x-not-multipart) userdata: 'b'.*'...'/Unhandled non-multipart (text\/x-not-multipart) userdata: 'b'REDACTED'...'/g" /var/log/cloud-init-output.log
fi

# Remove temporary files
rm -rf storage_file && rm -rf log_file
