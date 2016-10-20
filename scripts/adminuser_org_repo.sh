#!/bin/bash -ex

ADMININFO='/etc/gheadmin.conf'
GHE_ADMINUSER_NAME=`cat $ADMININFO| grep github_adminuser_name | awk -F':' '{print $2}'`
GHE_ADMINUSER_EMAIL=`cat $ADMININFO| grep github_adminuser_email | awk -F':' '{print $2}'`
GHE_ADMINUSER_PASSWD=`cat $ADMININFO| grep github_adminuser_password | awk -F':' '{print $2}'`
GHE_ORG=`cat $ADMININFO| grep github_organization | awk -F':' '{print $2}'`
GHE_REPO=`cat $ADMININFO| grep github_repository | awk -F':' '{print $2}'`

ORG=\"${GHE_ORG}\"
ADMIN_USER=\"${GHE_ADMINUSER_NAME}\"

EC2_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`

cat <<-EOF | ghe-console
  exit 1 if !GitHub.enterprise_first_run?

  USER = "${GHE_ADMINUSER_NAME}"
  EMAIL = "${GHE_ADMINUSER_EMAIL}"
  PASSWD = "${GHE_ADMINUSER_PASSWD}"

  user = User.create_with_random_password USER
  user.email = EMAIL
  user.password = user.password_confirmation = PASSWD
  if user.valid?
    user.save
  end
EOF

#rm -f ${ADMININFO}

MAKE_ORG=`curl -i -k -L -H "Content-Type: application/json" --write-out '%{http_code}' -d "{\"login\": ${ORG}, \"admin\": ${ADMIN_USER}}" -X POST https://${GHE_ADMINUSER_NAME}:${GHE_ADMINUSER_PASSWD}@${EC2_IP}/api/v3/admin/organizations`

echo ${MAKE_ORG}

MAKE_REPO=`curl -i -k -L -H "Content-Type: application/json" -d "{\"name\": \"${GHE_REPO}\", \"private\": \"true\", \"auto_init\": \"true\"}" -X POST https://${GHE_ADMINUSER_NAME}:${GHE_ADMINUSER_PASSWD}@${EC2_IP}/api/v3/orgs/${GHE_ORG}/repos`
# The above is supposed to return a 201
echo "The above is supposed to return to 201"
echo ${MAKE_REPO}

echo "Finished AWSQuickStart Bootstraping"
