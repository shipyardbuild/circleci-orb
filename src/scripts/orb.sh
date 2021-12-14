#!/usr/bin/env sh

# Install Python
if ! which python > /dev/null; then
    echo "Trying to install Python..."
    which apt-get > /dev/null && apt-get update -qq && apt-get install -qq python && echo Installed!
    which yum > /dev/null && yum install -y python && echo Installed!
fi

# Install pip
if ! which pip > /dev/null; then
    echo "Trying to install pip..."
    which apt-get > /dev/null && apt-get update -qq && apt-get install -qq python-pip && echo Installed!
    which yum > /dev/null && yum install -y python-pip && echo Installed!
fi

# Install wget
if ! which wget > /dev/null; then
    echo "Trying to install wget..."
    which apt-get > /dev/null && apt-get update -qq && apt-get install -qq wget && echo Installed!
    which yum > /dev/null && yum install -y wget && echo Installed!
fi

# Download the orb
cd /tmp || exit
wget https://github.com/shipyardbuild/circleci-orb/archive/refs/heads/convert-to-python.tar.gz
tar xvzf convert-to-python.tar.gz
cd /tmp/circleci-orb-convert-to-python/src/scripts || exit

# Run the orb
pip install -r requirements.txt
python orb.py 
