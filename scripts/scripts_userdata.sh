#!/bin/bash -ex
#UserData and or scripts should be stored here, but only for source code revision purposes and CloudFormation templates should always refer to 'quickstart-reference' S3 bucket
#
# Configuring the GitHub Enterprise server

DATE=`date +%d-%m-%Y`
date >/root/install_date
#echo "Installing Tools"
# Install tools needed for bootstraping
#easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
#wget https://bootstrap.pypa.io/get-pip.py
#sudo python get-pip.py
#pip install awscli

###########################################
#  Configure the GitHub Enterprise server
###########################################

ADMININFO='/etc/gheadmin.conf'
GHE_ADMIN_PASSWD=`cat $ADMININFO| grep github_admin_password | awk -F: '{print $2}'`
GHE_S3_BUCKET=`cat $ADMININFO| grep github_s3_bucket | awk -F: '{print $2}'`
GHE_LICENSE=`cat $ADMININFO| grep github_license_file | awk -F: '{print $2}'`
AWS_CMD='/usr/local/bin/aws'
EC2_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`

# Copy down the license file from the S3 Bucket
${AWS_CMD} s3 cp s3://${GHE_S3_BUCKET}/${GHE_LICENSE} /tmp
sleep 25

#Upload the license and set the GitHub Enterprise Admin password
curl -i -k -L -F license=@/tmp/${GHE_LICENSE} -F password=${GHE_ADMIN_PASSWD} -X POST https://${EC2_IP}:8443/setup/api/start 

# Initiate the configuration process
curl -i -k -L -X POST https://api_key:${GHE_ADMIN_PASSWD}@localhost:8443/setup/api/configure

# Get the default settings
curl -i -k -L https://api_key:${GHE_ADMIN_PASSWD}@localhost:8443/setup/api/settings

# Check the configuration status and continue to check until the configuration is complete
CONFIG_STATUS=`curl -k -L https://api_key:${GHE_ADMIN_PASSWD}@localhost:8443/setup/api/configcheck | awk -F, '{print $NF}' | awk -F: '{print $NF}' |tail -n1 `
while [[ ${CONFIG_STATUS} != *'DONE'* ]]; do
  sleep 2
  echo date
  echo 'Waiting for config status to contain done for Reloading application services'
  echo ${CONFIG_STATUS}
  CONFIG_STATUS=`curl -k -L https://api_key:${GHE_ADMIN_PASSWD}@localhost:8443/setup/api/configcheck | awk -F, '{print $NF}' | awk -F: '{print $NF}' |tail -n1 `
done
rm -f ${ADMININFO} 

echo "Finished AWSQuickStart Bootstraping"
