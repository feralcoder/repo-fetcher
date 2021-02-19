#!/bin/bash
THIS_SOURCE="$(dirname ${BASH_SOURCE[0]})"
ABS_PATH=$( readlink -f $THIS_SOURCE )
echo Running scripts from: $THIS_SOURCE
echo Apsolute path is: $ABS_PATH
echo


if [[ $USER != root ]]; then
  echo "Must be root to run this!"
  exit
fi

REPOSTORE=/repo-store/
HOSTIP=`ip addr | grep 192.168.127.220 | awk '{print $2}' | awk -F'/' '{print $1}'`

dnf -y install @nginx
yum -y install epel-release
yum -y install nginx
yum -y install wget tmux

systemctl enable --now nginx
systemctl status nginx

firewall-cmd --add-service=http --permanent
firewall-cmd --reload


### REPO STORE MANUALLY SET UP AND AVAILABLE

mkdir -p $REPOSTORE/repos/centos/8/
mkdir -p $REPOSTORE/logs/

cat $THIS_SOURCE/reposync_centos8.sh.template | sed "s|<<REPOSTORE>>|$REPOSTORE|g" > $THIS_SOURCE/reposync_centos8.sh
chmod 755 $THIS_SOURCE/reposync_centos8.sh
echo "# Fetch centos8 repos every Sunday at 3AM" > /etc/cron.d/repofetch_centos8
echo "0 3 * * Sun root $ABS_PATH/reposync_centos8.sh > $REPOSTORE/logs/repofetch_centos8_\`date +\%Y\%m\%d_\%H\%M\`.log 2>&1" >> /etc/cron.d/repofetch_centos8
systemctl reload crond.service

cat $THIS_SOURCE/nginx-repos.conf | sed "s,<<REPOSTORE>>,$REPOSTORE,g" | sed "s,<<HOSTIP>>,$HOSTIP,g" > /etc/nginx/conf.d/repos.conf

chcon -Rt httpd_sys_content_t /repo-store/
semanage fcontext -a -t httpd_sys_content_t "$REPOSTORE(/.*)?"

nginx -t
systemctl restart nginx

