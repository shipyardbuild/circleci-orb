#!/usr/bin/env sh

# Install Python
if ! which python > /dev/null; then
    echo "Trying to install Python..."

    which apt-get > /dev/null && \
        apt-get update -qq > /dev/null && \
        apt-get install -qq python > /dev/null && \
        echo Installed!

    which yum > /dev/null && \
        yum install -y python > /dev/null && \
        echo Installed!
fi

# Install pip
if ! which pip > /dev/null; then
    echo "Trying to install pip..."

    which apt-get > /dev/null && \
        apt-get update -qq > /dev/null && \
        apt-get install -qq python-pip > /dev/null && \
        echo Installed!

    which yum > /dev/null && \
        yum install -y python-pip > /dev/null && \
        echo Installed!
fi

# Install wget
if ! which wget > /dev/null; then
    echo "Trying to install wget..."

    which apt-get > /dev/null && \
        apt-get update -qq > /dev/null && \
        apt-get install -qq wget > /dev/null && \
        echo Installed!

    which yum > /dev/null && \
        yum install -y wget > /dev/null && \
        echo Installed!
fi

# Download the orb
# cd /tmp || exit
# wget -q https://github.com/shipyardbuild/circleci-orb/archive/refs/heads/master.tar.gz
# wget -q https://github.com/shipyardbuild/circleci-orb/archive/refs/heads/akshaykalia6299/sc-13326/shipyard-orb-and-github-action-should-accept.tar.gz
# tar xvzf shipyard-orb-and-github-action-should-accept.tar.gz > /dev/null
cd src/scripts || exit

# Run the orb
pip install -r requirements.txt > /dev/null
python orb.py 
