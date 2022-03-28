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
cd /tmp || exit
wget -q https://github.com/shipyardbuild/circleci-orb/archive/refs/heads/azlyth/add-environment-and-timeout.tar.gz
tar xvzf add-environment-and-timeout.tar.gz > /dev/null
cd /tmp/circleci-orb-azlyth-add-environment-and-timeout/src/scripts || exit

# Run the orb
pip install -r requirements.txt > /dev/null
python orb.py 
