#!/usr/bin/env bash
set -eo pipefail
export DEBIAN_FRONTEND=noninteractive
export WFLOW_REPO=${WFLOW_REPO:-"https://github.com/pahaz/dokku.git"}
export WFLOW_BRANCH=q

if ! which apt-get &>/dev/null
then
  echo "This installation script requires apt-get. For manual installation instructions, consult https://github.com/progrium/dokku ."
  exit 1
fi

apt-get update
apt-get install -y git make curl software-properties-common

[[ `lsb_release -sr` == "12.04" ]] && apt-get install -y python-software-properties

cd ~ && test -d wflow || git clone $WFLOW_REPO wflow
cd wflow
git fetch origin

if [[ -n $WFLOW_BRANCH ]]; then
  git checkout origin/$WFLOW_BRANCH
elif [[ -n $WFLOW_TAG ]]; then
  git checkout $WFLOW_TAG
fi

make install

echo
echo "Almost done! For next steps on configuration:"
echo "  https://github.com/progrium/dokku#configuring"
