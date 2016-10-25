#!/bin/bash -ex

# ARGS for script
# 1: GHE_ADMINUSER_NAME
# 2: GHE_ADMINUSER_EMAIL
# 3: GHE_ADMINUSER_PASSWD
# 4: GHE_ORG
# 5: GHE_REPO

ORG=\"$4\"
ADMIN_USER=\"$1\"

EC2_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`

cat <<-EOF | ghe-console
  exit 1 if !GitHub.enterprise_first_run?

  USER = "$1"
  EMAIL = "$2"
  PASSWD = "$3"

  user = User.create_with_random_password USER
  user.email = EMAIL
  user.password = user.password_confirmation = PASSWD
  if user.valid?
    user.save
  end
EOF

MAKE_ORG=`curl -i -k -L -H "Content-Type: application/json" --write-out '%{http_code}' -d "{\"login\": ${ORG}, \"admin\": ${ADMIN_USER}}" -X POST https://$1:$3@${EC2_IP}/api/v3/admin/organizations`

echo ${MAKE_ORG}

MAKE_REPO=`curl -i -k -L -H "Content-Type: application/json" -d "{\"name\": \"$5\", \"private\": \"true\", \"auto_init\": \"true\"}" -X POST https://$1:$3@${EC2_IP}/api/v3/orgs/$4/repos`
# The above is supposed to return a 201
echo "The above is supposed to return to 201"
echo ${MAKE_REPO}

#rm -f ${ADMININFO}
echo "Finished AWSQuickStart Bootstraping"
