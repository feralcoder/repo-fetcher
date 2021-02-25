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

REPOIP=192.168.127.220

cd /etc/yum.repos.d/
mkdir old-repos
mv *.repo old-repos
mv old-repos/CentOS-Linux-Sources.repo .
mv epel* .

cat $ABS_PATH/feralcoder.repo | sed "s|<<REPOIP>>|$REPOIP|g" > ./feralcoder.repo

yum clean all
yum makecache
yum repolist
yum -y update
yum install yum-utils
yum-config-manager --enable PowerTools
#yum-config-manager --enable centosplus
