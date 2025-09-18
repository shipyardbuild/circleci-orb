#!/usr/bin/env sh

# Set environment variables to prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Check if sudo available
if [ "$(id -u)" = 0 ]; then export SUDO=""; else # Check if we are root
  export SUDO="sudo";
fi

# Run apt-get update once if needed (skip Google Chrome setup as it's not needed for Python)
if which apt-get > /dev/null; then
    echo "Updating package lists..."
    $SUDO apt-get update -qq > /dev/null 2>&1 || echo "Warning: apt-get update had some issues, continuing..."
fi

# Install Python
if ! which python3 --version > /dev/null; then
    echo "Trying to install Python..."

    if which apt-get > /dev/null; then
        $SUDO apt-get install -y -qq --no-install-recommends python3 python3-six apt-utils > /dev/null 2>&1 && echo "Python installed!"
    elif which yum > /dev/null; then
        $SUDO yum install -y python3 python3-six > /dev/null 2>&1 && echo "Python installed!"
    fi

    $SUDO ln -sf /usr/bin/python3 /usr/bin/python > /dev/null
fi

# Install pip
if ! which pip > /dev/null; then
    echo "Trying to install pip..."

    if which apt-get > /dev/null; then
        $SUDO apt-get install -y -qq --no-install-recommends python3-pip > /dev/null 2>&1 && echo "pip installed!"
    elif which yum > /dev/null; then
        $SUDO yum install -y python3-pip > /dev/null 2>&1 && echo "pip installed!"
    fi

    $SUDO ln -sf /usr/bin/pip3 /usr/bin/pip > /dev/null
fi

# Always install python-venv to ensure it's available
echo "Installing python3-venv..."
PYTHON_VERSION=$(python --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
echo "Detected Python version: $PYTHON_VERSION"

if which apt-get > /dev/null; then
    # Debian/Ubuntu
    # Try version-specific package first (e.g., python3.11-venv), then fall back to generic
    if $SUDO apt-get install -y -qq --no-install-recommends "python${PYTHON_VERSION}-venv" > /dev/null 2>&1; then
        echo "python${PYTHON_VERSION}-venv installed!"
    else
        echo "Falling back to generic python3-venv package..."
        $SUDO apt-get install -y -qq --no-install-recommends python3-venv > /dev/null 2>&1 && echo "python3-venv installed!"
    fi
elif which yum > /dev/null; then
    # RHEL/CentOS/Fedora
    $SUDO yum install -y python3-venv > /dev/null 2>&1 && echo "python3-venv installed!"
elif which dnf > /dev/null; then
    # Fedora (newer versions)
    $SUDO dnf install -y python3-venv > /dev/null 2>&1 && echo "python3-venv installed!"
elif which apk > /dev/null; then
    # Alpine Linux
    $SUDO apk add --no-cache python3-venv > /dev/null 2>&1 && echo "python3-venv installed!"
else
    echo "Warning: Could not detect package manager to install python3-venv"
fi

# Install wget
if ! which wget > /dev/null; then
    echo "Trying to install wget..."

    if which apt-get > /dev/null; then
        $SUDO apt-get install -y -qq --no-install-recommends wget > /dev/null 2>&1 && echo "wget installed!"
    elif which yum > /dev/null; then
        $SUDO yum install -y wget > /dev/null 2>&1 && echo "wget installed!"
    fi
    echo "wget installed!"
fi

# Download the orb
cd /tmp || exit

wget -q https://github.com/shipyardbuild/circleci-orb/archive/refs/heads/chore/add-logs.tar.gz

tar xvzf add-logs.tar.gz > /dev/null

cd /tmp/circleci-orb-chore-add-logs/src/scripts || exit

# Create a virtual environment
python -m venv /tmp/orb_env

# Activate the virtual environment
# shellcheck disable=SC1091
. /tmp/orb_env/bin/activate

# Install the required packages
pip install -r requirements.txt > /dev/null

# Run the orb
python orb.py
