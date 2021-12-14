#!/usr/bin/env sh

# Install Python if needed
if ! which python > /dev/null; then
    echo "Trying to install Python..."
    which apt-get > /dev/null && apt-get update -qq && apt-get install -qq python
    which yum > /dev/null && yum install -y python
fi

# Install wget if needed
if ! which wget > /dev/null; then
    echo "Trying to install wget..."
    which apt-get > /dev/null && apt-get update -qq && apt-get install -qq wget
    which yum > /dev/null && yum install -y wget
fi

# Download the orb
cd /tmp || exit
wget https://github.com/shipyardbuild/circleci-orb/archive/refs/heads/convert-to-python.tar.gz
tar xvzf convert-to-python.tar.gz
cd /tmp/circleci-orb-convert-to-python/src/scripts || exit

# Run the orb
pip install -r requirements.txt
python orb.py 
