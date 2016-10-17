#!/bin/bash -ex

ADMININFO='/etc/gheadmin.conf'
GHE_ADMINUSER_NAME=\"`cat $ADMININFO| grep github_adminuser_name | awk -F':' '{print $2}'`\"
GHE_ADMINUSER_EMAIL=\"`cat $ADMININFO| grep github_adminuser_email | awk -F':' '{print $2}'`\"
GHE_ADMINUSER_PASSWD=\"`cat $ADMININFO| grep github_adminuser_password | awk -F':' '{print $2}'`\"

cat <<-EOF | ghe-console
  exit 1 if !GitHub.enterprise_first_run?

  USER = ${GHE_ADMINUSER_NAME}
  EMAIL = ${GHE_ADMINUSER_EMAIL}
  PASSWD = ${GHE_ADMINUSER_PASSWD}

  user = User.create_with_random_password USER
  user.email = EMAIL
  user.password = user.password_confirmation = PASSWD
  if user.valid?
    user.save
  end
EOF

rm -f ${ADMININFO}

echo "Finished AWSQuickStart Bootstraping"
