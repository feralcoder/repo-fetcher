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
[[ -d old-repos ]] || mkdir old-repos
mv *.repo old-repos
mv old-repos/CentOS-Linux-Sources.repo .
mv old-repos/epel* .

get_os_version () {
  if ( grep -i 'centos\|rhel' /etc/redhat-release ); then
    OS=CENTOS
    RELEASE=`cat /etc/redhat-release | sed 's/ /\n/g' | grep '[0-9]'`
    MAJOR=`echo $RELEASE | awk -F'.' '{print $1}'`
  fi
}


get_os_version
if [[ $MAJOR == 8 ]]; then
  cat $ABS_PATH/feralcoder.8.repo | sed "s|<<REPOIP>>|$REPOIP|g" > ./feralcoder.repo
elif [[ $MAJOR == 7 ]]; then
  echo "WE NEED CENTOS7 REPO FILE!"
fi
cat $ABS_PATH/feralcoder-puppet.repo | sed "s|<<REPOIP>>|$REPOIP|g" > ./feralcoder-puppet.repo
cp $ABS_PATH/feralcoder-puppet-upstream7.repo ./feralcoder-puppet-upstream7.repo
cp $ABS_PATH/feralcoder-puppet-upstream8.repo ./feralcoder-puppet-upstream8.repo
cat $ABS_PATH/feralcoder-docker.repo | sed "s|<<REPOIP>>|$REPOIP|g" > ./feralcoder-docker.repo
cp $ABS_PATH/feralcoder-docker-upstream7.repo ./feralcoder-docker-upstream7.repo
cp $ABS_PATH/feralcoder-docker-upstream8.repo ./feralcoder-docker-upstream8.repo

yum clean all
yum makecache
yum repolist

# The following is necessary to unwedge system updates after adding docker repo.
dnf -y erase buildah podman

#yum -y update
#yum -y install yum-utils
#yum-config-manager --enable PowerTools
#yum-config-manager --enable centosplus
