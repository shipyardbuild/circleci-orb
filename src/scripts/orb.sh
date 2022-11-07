#!/usr/bin/env sh

# Check if sudo available
ADD_SUDO=$(if which sudo > /dev/null; then echo "sudo"; else echo ""; fi)

# Install Python
if ! which python > /dev/null; then
    echo "Trying to install Python..."

    which apt-get > /dev/null && \
        $ADD_SUDO apt-get update -qq > /dev/null && \
        $ADD_SUDO apt-get install -qq python3 python-is-python3 > /dev/null && \
        echo Installed!

    which yum > /dev/null && \
        yum install -y python > /dev/null && \
        echo Installed!
fi

# Install pip
if ! which pip > /dev/null; then
    echo "Trying to install pip..."

    which apt-get > /dev/null && \
        $ADD_SUDO apt-get update -qq > /dev/null && \
        $ADD_SUDO apt-get install -qq python3-pip > /dev/null && \
        alias pip=pip3 && \
        echo Installed!

    which yum > /dev/null && \
        yum install -y python-pip > /dev/null && \
        echo Installed!
fi

# Install wget
if ! which wget > /dev/null; then
    echo "Trying to install wget..."

    which apt-get > /dev/null && \
        $ADD_SUDO apt-get update -qq > /dev/null && \
        $ADD_SUDO apt-get install -qq wget > /dev/null && \
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
pwd
ls

cd ${CIRCLE_WORKING_DIRECTORY}/src/scripts || exit

ls

# Run the orb
pip install -r requirements.txt > /dev/null
python orb.py 
