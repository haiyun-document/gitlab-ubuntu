#!/bin/sh
#############################################################
##
##	The standard sh shell is used
##	(dash on ubuntu) because it's
##	the closest to a posix-compliant
##	shell that ships with ubuntu
##	by default. 
##
#############################################################

#############################################################
##
##	CONFIGURATION OPTIONS
##
#############################################################

REQUIRED_PACKAGES="git git-core gcc libxml2-dev libxslt-dev sqlite3 libsqlite3-dev \
	libcurl4-openssl-dev libreadline6-dev libc6-dev libssl-dev make build-essential \
	zlib1g-dev libicu-dev redis-server openssh-server python-dev python-pip libyaml-dev \
	postfix ruby1.9.3"
	
CHUSR="sudo -H -u"

#############################################################
##
##	MAIN
##
#############################################################

#----------- Ensure Root Access -----------

if [ "$(id -u)" != "0" ];
then
	echo "Must be run as root. Exiting." 
	exit 1
fi

#----------- Install Prerequisites -----------

apt-get install -y $REQUIRED_PACKAGES

#----------- Add users -----------

adduser --system --shell /bin/sh --gecos 'git user' --group \
	--disabled-password --home /home/git git
	
adduser --disabled-login --gecos 'gitlab system user' gitlab

#----------- Add users to eachother's groups -----------

usermod -a -G git gitlab
usermod -a -G gitlab git

#----------- Generate RSA key ------------

$CHUSR gitlab ssh-keygen -q -N '' -t rsa -f /home/gitlab/.ssh/id_rsa

cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub
chmod 0444 /home/git/gitlab.pub

#----------- Install and configure Gitolite -----------

# NOTE: This uses the fork of gitolite tweaked for GitLab

cd /home/git

$CHUSR git mkdir bin
$CHUSR git git clone -b gl-v304 https://github.com/gitlabhq/gitolite.git gitolite-src
$CHUSR git echo "PATH=\$PATH:/home/git/bin" >> /home/git/.profile
$CHUSR git echo "export PATH" >> /home/git/.profile
$CHUSR git gitolite-src/install -ln /home/git/bin
$CHUSR git PATH=/home/git/bin:$PATH
$CHUSR git gitolite setup -pk /home/git/gitlab.pub

chmod -R g+rwX /home/git/repositories/
chown -R git:git /home/git/repositories/

#----------- Test the Install -------------

$CHUSR gitlab git clone git@localhost:gitolite-admin.git /tmp/gitolite-admin
rm -rf /tmp/gitolite-admin





