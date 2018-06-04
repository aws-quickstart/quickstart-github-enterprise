#!/bin/bash 
# GitHub Enterprise 
# date:  Nov,3,2016

# ARGS for script
# 1: GHE_ADMINUSER_NAME
# 2: GHE_ADMINUSER_EMAIL
# 3: GHE_ADMINUSER_PASSWD
# 4: GHE_ORG
# 5: GHE_REPO

ORG=\"$4\"
ADMIN_USER=\"$1\"

EC2_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`


##########################################
# Check status function
##########################################
function chkstatus () {
if [ $1 -eq 201 ]
then
  echo "Script $0 [PASS]"
else
  echo "Script $0 [FAILED]" >&2
  exit 1
fi
}

  echo "Creating first GitHub Enterprise administrator account"
  TEMPDIR=`mktemp -d /tmp/XXXXXXXXXXXXX`
  echo $TEMPDIR
  curl -iskL https://$EC2_IP/join | grep 'Status: 200 OK'
  curl -k -v -L -c $TEMPDIR/cookies https://$EC2_IP/login > $TEMPDIR/github-curl.out
    authenticity_token=$(grep 'name="authenticity_token"' $TEMPDIR/github-curl.out | head -1 | sed -e 's/.*value="\([^"]*\)".*/\1/')
    curl -X POST -k -v -b $TEMPDIR/cookies -c -L $TEMPDIR/cookies \
    -F "authenticity_token=$authenticity_token" \
    -F "user[login]=$1" \
    -F "user[email]=$2" \
    -F "user[password]=$3" \
    -F "user[password_confirmation]=$3" \
    -F "source_label=Detail Form" \
    https://$EC2_IP/join >$TEMPDIR/github-curl.out 2>&1
    cat $TEMPDIR/github-curl.out
    grep "< Set-Cookie: logged_in=yes;" $TEMPDIR/github-curl.out
    rm -rf $TEMPDIR

MAKE_ORG=$(curl -i -k -L -H "Content-Type: application/json" --write-out '%{http_code}' --silent -d "{\"login\": ${ORG}, \"admin\": ${ADMIN_USER}}" -X POST https://$1:$3@${EC2_IP}/api/v3/admin/organizations)

RETURN_MAKE_ORG=`echo ${MAKE_ORG} | awk -F' ' '{print $NF}'`
echo "The Make Org HTTP status code: " ${RETURN_MAKE_ORG}

# Checking status, creation of an Organization should return a 201 on success
chkstatus $RETURN_MAKE_ORG
echo $?

MAKE_REPO=$(curl -i -k -L -H "Content-Type: application/json" --write-out '%{http_code}' --silent -d "{\"name\": \"$5\", \"private\": \"true\", \"auto_init\": \"true\"}" -X POST https://$1:$3@${EC2_IP}/api/v3/orgs/$4/repos)
# The above is supposed to return a 201
RETURN_MAKE_REPO=`echo ${MAKE_REPO} | awk -F' ' '{print $NF}'`
echo "The Make Repo HTTP status code: " ${RETURN_MAKE_REPO}

# Checking status, creation of an Organization should return a 201 on success
chkstatus $RETURN_MAKE_REPO
echo "The below is the exit code"
echo $?

#rm -f ${ADMININFO}
echo "Finished AWSQuickStart Bootstraping"
