#!/usr/bin/env sh

# Check if sudo available
if [ "$(id -u)" = 0 ]; then export SUDO=""; else # Check if we are root
  export SUDO="sudo";
fi

which python
which apt-get
python --version

# Install Python
if ! which python > /dev/null; then
    echo "Trying to install Python..."

    which apt-get > /dev/null && \
        $SUDO apt-get update -qq > /dev/null && \
        $SUDO apt-get install -qq python3 python-is-python3 python3-six > /dev/null && \
        echo Installed!

    which yum > /dev/null && \
        yum install -y python3 python-is-python3 python3-six > /dev/null && \
        echo Installed!

    python --version
fi

# Install pip
if ! which pip > /dev/null; then
    echo "Trying to install pip..."

    which apt-get > /dev/null && \
        $SUDO apt-get update -qq > /dev/null && \
        $SUDO apt-get install -qq python3-pip > /dev/null && \
        echo Installed!

    which yum > /dev/null && \
        yum install -y python3-pip > /dev/null && \
        echo Installed!

    $SUDO ln -s /usr/bin/pip3 /usr/bin/pip > /dev/null
fi

# Install wget
if ! which wget > /dev/null; then
    echo "Trying to install wget..."

    which apt-get > /dev/null && \
        $SUDO apt-get update -qq > /dev/null && \
        $SUDO apt-get install -qq wget > /dev/null && \
        echo Installed!

    which yum > /dev/null && \
        yum install -y wget > /dev/null && \
        echo Installed!
fi

# Download the orb
cd /tmp || exit
wget -q https://github.com/shipyardbuild/circleci-orb/archive/refs/heads/master.tar.gz
tar xvzf master.tar.gz > /dev/null

cd /tmp/circleci-orb-master/src/scripts || exit

# Run the orb
pip install -r requirements.txt > /dev/null
python orb.py 
