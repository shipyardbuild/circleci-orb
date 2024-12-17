#!/usr/bin/env sh

# Check if sudo available
if [ "$(id -u)" = 0 ]; then export SUDO=""; else # Check if we are root
  export SUDO="sudo";
fi

# Fix Cert error - https://www.omgubuntu.co.uk/2017/08/fix-google-gpg-key-linux-repository-error
wget -q -O /usr/share/keyrings/google-keyring.gpg https://dl.google.com/linux/linux_signing_key.pub
echo "deb [signed-by=/usr/share/keyrings/google-keyring.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | $SUDO tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

# Install Python
if ! which python3 --version > /dev/null; then
    echo "Trying to install Python..."

    which apt-get > /dev/null && \
        $SUDO apt-get update -qq > /dev/null && \
        $SUDO apt-get install -qq python3 python3-six apt-utils > /dev/null && \
        echo Installed!

    which yum > /dev/null && \
        yum install -y python3 python3-six > /dev/null && \
        echo Installed!

    $SUDO ln -sf /usr/bin/python3 /usr/bin/python > /dev/null
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

    $SUDO ln -sf /usr/bin/pip3 /usr/bin/pip > /dev/null
fi

# Check if pipx is installed, if not, install it
if ! command -v pipx > /dev/null; then
    echo "Installing pipx..."
    which apt-get > /dev/null && \
        $SUDO apt-get update -qq > /dev/null && \
        $SUDO apt-get install -qq pipx > /dev/null && \
        echo "pipx installed!"

    which yum > /dev/null && \
        yum install -y pipx > /dev/null && \
        echo "pipx installed!"

    # Ensure pipx path is set
    pipx ensurepath
fi

# Check if python3-venv is installed, if not, install it
if ! dpkg -l | grep -q python3-venv; then
    echo "Installing python3-venv..."
    which apt-get > /dev/null && \
        $SUDO apt-get update -qq > /dev/null && \
        $SUDO apt-get install -qq python3-venv > /dev/null && \
        echo "python3-venv installed!"

    which yum > /dev/null && \
        yum install -y python3-venv > /dev/null && \
        echo "python3-venv installed!"
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
wget -q https://github.com/shipyardbuild/circleci-orb/archive/refs/heads/chore/update-google-gpg.tar.gz
tar xvzf update-google-gpg.tar.gz > /dev/null

cd /tmp/circleci-orb-chore-update-google-gpg/src/scripts || exit

# Use virtual environment
#python3 -m venv /tmp/orb_env
# Use POSIX-compliant dot command for source
#. /tmp/orb_env/bin/activate

# Run the orb
#pip install -r requirements.txt > /dev/null
#python orb.py

# Create a virtual environment
python3 -m venv /tmp/orb_env

# Activate the virtual environment
. /tmp/orb_env/bin/activate

# Install the required packages
pip install -r requirements.txt

# Run the orb
python orb.py
