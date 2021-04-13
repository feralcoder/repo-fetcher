#!/bin/bash


sudo yum install -y zsh
mkdir -p ~/CODE/pagure.io && cd ~/CODE/pagure.io && git clone https://pagure.io/quick-fedora-mirror.git
cd ~/CODE/pagure.io/quick-fedora-mirror

sudo mkdir -p /repo-store/repos/fedora

cp ~/CODE/feralcoder/repo-fetcher/fedora/quick-fedora-mirror.conf ./
XXX=~/CODE/pagure.io/quick-fedora-mirror/quick-fedora-mirror.conf.dist
[[ -f $XXX.orig ]] || cp $XXX $XXX.orig
if ( diff $XXX.orig ~/CODE/feralcoder/repo-fetcher/fedora/quick-fedora-mirror.conf.dist.orig ); then
  echo $XXX has changed in the upstream, please resolve.
  return 1
fi


# FIRST RUN
FIRST_RUN_SINCE="-T 'last year'"
# RUN FROM CRON:
~/CODE/pagure.io/quick-fedora-mirror/quick-fedora-mirror -c ~/CODE/feralcoder/repo-fetcher/fedora/quick-fedora-mirror.conf
