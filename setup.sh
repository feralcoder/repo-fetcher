#!/bin/bash
THIS_SOURCE="$(dirname ${BASH_SOURCE[0]})"
ABS_PATH=$( readlink -f $THIS_SOURCE )

if [[ $USER != root ]]; then
  echo "Must be root to run this!"
  exit
fi

REPOSTORE=/repo-store/
HOSTIP=`ip addr | grep 192.168.127.220 | awk '{print $2}' | awk -F'/' '{print $1}'`

( yum list installed createrepo_c ) || yum -y install createrepo_c
( yum list installed wget ) || yum -y install wget
( yum list installed tmux ) || yum -y install tmux
( yum list installed nginx ) || yum -y install @nginx
( yum list installed epel-release ) || yum -y install epel-release

systemctl enable --now nginx
systemctl status nginx

firewall-cmd --add-service=http --permanent
firewall-cmd --reload

### REPO STORE MANUALLY SET UP AND AVAILABLE

mkdir -p $REPOSTORE/fetch-repos/mariadb-upstream/
mkdir -p $REPOSTORE/repos/MariaDB/
mkdir -p $REPOSTORE/repos/puppet7/el/7/
mkdir -p $REPOSTORE/repos/puppet7/el/8/
mkdir -p $REPOSTORE/repos/puppet6/el/7/
mkdir -p $REPOSTORE/repos/puppet6/el/8/
mkdir -p $REPOSTORE/repos/docker/centos/7/
mkdir -p $REPOSTORE/repos/docker/centos/8/
mkdir -p $REPOSTORE/repos/centos/7/
mkdir -p $REPOSTORE/repos/centos-altarch/7/kernel/x86_64/
mkdir -p $REPOSTORE/repos/centos/8/
mkdir -p $REPOSTORE/repos/centos/8-stream/
mkdir -p $REPOSTORE/logs/

cat $THIS_SOURCE/reposync.sh.template | sed "s|<<REPOSTORE>>|$REPOSTORE|g" > $THIS_SOURCE/reposync.sh
chmod 755 $THIS_SOURCE/reposync.sh
echo "# Fetch centos8 repos every Sunday at 3AM" > /etc/cron.d/repofetch_centos8
echo "0 3 * * Sun root $ABS_PATH/reposync.sh > $REPOSTORE/logs/repofetch_centos8_\`date +\%Y\%m\%d_\%H\%M\`.log 2>&1" >> /etc/cron.d/repofetch_centos8
systemctl reload crond.service

cat $THIS_SOURCE/nginx-repos.conf | sed "s,<<REPOSTORE>>,$REPOSTORE,g" | sed "s,<<HOSTIP>>,$HOSTIP,g" > /etc/nginx/conf.d/repos.conf

chcon -Rt httpd_sys_content_t /repo-store/
semanage fcontext -a -t httpd_sys_content_t "$REPOSTORE(/.*)?"

nginx -t
systemctl restart nginx

