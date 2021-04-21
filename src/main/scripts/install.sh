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

while getopts "l:u:p:t:j:" opt; do
    case $opt in
        l)
            imKitLocation=$OPTARG #SAS URI of the IBM Installation Manager install kit in Azure Storage
        ;;
        u)
            userName=$OPTARG #IBM user id for downloading artifacts from IBM web site
        ;;
        p)
            password=$OPTARG #password of IBM user id for downloading artifacts from IBM web site
        ;;
        t)
            wasNDTraditional=$OPTARG #IBM WebSphere Application Server ND Traditional version
        ;;
        j)
            ibmJavaSDK=$OPTARG #IBM Java SDK version
        ;;        
    esac
done

# Variables
SSLPREF="com.ibm.cic.common.core.preferences.ssl.nonsecureMode=false"
DOWNLOADPREF="com.ibm.cic.common.core.preferences.preserveDownloadedArtifacts=false"
imKitName=agent.installer.linux.gtk.x86_64_1.9.zip
repositoryUrl=https://www.ibm.com/software/repositorymanager/entitled

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

# Create installation directories
mkdir -p /datadrive/IBM/InstallationManager/V1.9 && mkdir -p /datadrive/IBM/WebSphere/ND/V9 && mkdir -p /datadrive/IBM/IMShared

# Install IBM Installation Manager
wget -O "$imKitName" "$imKitLocation" -q
mkdir im_installer
unzip -q "$imKitName" -d im_installer
./im_installer/userinstc -log log_file -acceptLicense -installationDirectory /datadrive/IBM/InstallationManager/V1.9

# Install IBM WebSphere Application Server Network Deployment V9 using IBM Instalation Manager
/datadrive/IBM/InstallationManager/V1.9/eclipse/tools/imutilsc saveCredential -secureStorageFile storage_file \
    -userName "$userName" -userPassword "$password" -passportAdvantage
/datadrive/IBM/InstallationManager/V1.9/eclipse/tools/imcl install "$wasNDTraditional" "$ibmJavaSDK" -repositories "$repositoryUrl" \
    -installationDirectory /datadrive/IBM/WebSphere/ND/V9/ -sharedResourcesDirectory /datadrive/IBM/IMShared/ \
    -secureStorageFile storage_file -acceptLicense -preferences $SSLPREF,$DOWNLOADPREF -showProgress

# Move WAS entitlement check and application patch script to /var/lib/cloud/scripts/per-instance
mv was-check.sh /var/lib/cloud/scripts/per-instance
