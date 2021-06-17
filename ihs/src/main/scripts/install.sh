#!/bin/sh

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

while getopts "u:p:" opt; do
    case $opt in
        u)
            userName=$OPTARG #IBM user id for downloading artifacts from IBM web site
        ;;
        p)
            password=$OPTARG #password of IBM user id for downloading artifacts from IBM web site
        ;;
    esac
done

# Wait untile the data disk is partitioned and mounted
output=$(df -h)
while echo $output | grep -qv "/datadrive"
do
    sleep 10
    echo "Waiting for data disk partition & moute complete..."
    output=$(df -h)
done
name=$(df -h | grep "/datadrive" | awk '{print $1;}' | grep -Po "(?<=\/dev\/).*")
echo "UUID=$(blkid | grep -Po "(?<=\/dev\/${name}\: UUID=\")[^\"]*(?=\".*)")   /datadrive   xfs   defaults,nofail   1   2" >> /etc/fstab

# Move entitlement check and application patch script to /var/lib/cloud/scripts/per-instance
mv was-check.sh /var/lib/cloud/scripts/per-instance

# Move installation properties file to /datadrive
mv virtualimage.properties /datadrive

# Get installation properties
source /datadrive/virtualimage.properties

# Create installation directories
mkdir -p ${IM_INSTALL_DIRECTORY} && mkdir -p ${IM_SHARED_DIRECTORY} \
    && mkdir -p ${IHS_INSTALL_DIRECTORY} && mkdir -p ${PLUGIN_INSTALL_DIRECTORY} && mkdir -p ${WCT_INSTALL_DIRECTORY}

# Install IBM Installation Manager
wget -O "$IM_INSTALL_KIT" "$IM_INSTALL_KIT_URL" -q
mkdir im_installer
unzip -q "$IM_INSTALL_KIT" -d im_installer
./im_installer/userinstc -log log_file -acceptLicense -installationDirectory ${IM_INSTALL_DIRECTORY}

# Check whether IBMid is entitled or not
${IM_INSTALL_DIRECTORY}/eclipse/tools/imutilsc saveCredential -secureStorageFile storage_file \
    -userName "$userName" -userPassword "$password" -passportAdvantage
if [ $? -eq 0 ]; then
    output=$(${IM_INSTALL_DIRECTORY}/eclipse/tools/imcl listAvailablePackages -cPA -secureStorageFile storage_file)
    if echo "$output" | grep "$WAS_ND_VERSION_ENTITLED"; then
        echo "IBM account entitlement check succeed."
    else
        echo "IBM account entitlement check failed."
        exit 1
    fi
else
    echo "Cannot connect to Passport Advantage."
    exit 1
fi

# Save credentials to a secure storage fileInstall
${IM_INSTALL_DIRECTORY}/eclipse/tools/imutilsc saveCredential -secureStorageFile storage_file \
    -userName "$userName" -userPassword "$password" -passportAdvantage

# Install IBM HTTP Server V9 using IBM Instalation Manager
${IM_INSTALL_DIRECTORY}/eclipse/tools/imcl install "$IBM_HTTP_SERVER" "$IBM_JAVA_SDK" -repositories "$REPOSITORY_URL" \
    -installationDirectory ${IHS_INSTALL_DIRECTORY}/ -sharedResourcesDirectory ${IM_SHARED_DIRECTORY}/ \
    -secureStorageFile storage_file -acceptLicense -preferences $SSL_PREF,$DOWNLOAD_PREF -showProgress

# Install Web Server Plug-ins V9 for IBM WebSphere Application Server using IBM Instalation Manager
${IM_INSTALL_DIRECTORY}/eclipse/tools/imcl install "$WEBSPHERE_PLUGIN" "$IBM_JAVA_SDK" -repositories "$REPOSITORY_URL" \
    -installationDirectory ${PLUGIN_INSTALL_DIRECTORY}/ -sharedResourcesDirectory ${IM_SHARED_DIRECTORY}/ \
    -secureStorageFile storage_file -acceptLicense -preferences $SSL_PREF,$DOWNLOAD_PREF -showProgress

# Install WebSphere Customization Toolbox V9 using IBM Instalation Manager
${IM_INSTALL_DIRECTORY}/eclipse/tools/imcl install "$WEBSPHERE_WCT" "$IBM_JAVA_SDK" -repositories "$REPOSITORY_URL" \
    -installationDirectory ${WCT_INSTALL_DIRECTORY}/ -sharedResourcesDirectory ${IM_SHARED_DIRECTORY}/ \
    -secureStorageFile storage_file -acceptLicense -preferences $SSL_PREF,$DOWNLOAD_PREF -showProgress

# Remove temporary files
rm -rf storage_file && rm -rf log_file
