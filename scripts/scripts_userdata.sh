#!/bin/bash -ex
#UserData and or scripts should be stored here, but only for source code revision purposes and CloudFormation templates should always refer to 'quickstart-reference' S3 bucket
#
# Configuring the GitHub Enterprise server

DATE=`date +%d-%m-%Y`
date >/root/install_date

###########################################
#  Configure the GitHub Enterprise server
###########################################

AWS_CMD='/usr/local/bin/aws'
EC2_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`

# ARGS for script
# 1: GHE_CONSOLE_PASSWORD
# 2: GHE_S3_BUCKET
# 3: GHE_LICENSE


# Copy down the license file from the S3 Bucket
${AWS_CMD} s3 cp s3://$2/$3 /tmp
sleep 25

#Upload the license and set the GitHub Enterprise Admin password
curl -i -k -L -F license=@/tmp/$3 -F password=$1 -X POST https://${EC2_IP}:8443/setup/api/start 

# Initiate the configuration process
curl -i -k -L -X POST https://api_key:$1@localhost:8443/setup/api/configure

# Get the default settings
curl -i -k -L https://api_key:$1@localhost:8443/setup/api/settings

# Check the configuration status and continue to check until the configuration is complete
CONFIG_STATUS=`curl -k -L https://api_key:$1@localhost:8443/setup/api/configcheck | awk -F, '{print $NF}' | awk -F: '{print $NF}' |tail -n1 `
while [[ ${CONFIG_STATUS} != *'DONE'* ]]; do
  sleep 2
  echo date
  echo 'Waiting for config status to contain done for Reloading application services'
  echo ${CONFIG_STATUS}
  CONFIG_STATUS=`curl -k -L https://api_key:$1@localhost:8443/setup/api/configcheck | awk -F, '{print $NF}' | awk -F: '{print $NF}' |tail -n1 `
done
