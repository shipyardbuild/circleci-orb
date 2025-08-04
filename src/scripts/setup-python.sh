#!/usr/bin/env sh

# Check if sudo available
if [ "$(id -u)" = 0 ]; then export SUDO=""; else # Check if we are root
  export SUDO="sudo";
fi

# Fix Cert error - https://www.omgubuntu.co.uk/2017/08/fix-google-gpg-key-linux-repository-error
if ! $SUDO wget -q -O /usr/share/keyrings/google-keyring.gpg https://dl.google.com/linux/linux_signing_key.pub; then
    echo "Failed to download Google signing key"
    exit 1
fi
echo "deb [signed-by=/usr/share/keyrings/google-keyring.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | $SUDO tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

# Run apt-get update once if needed
if which apt-get > /dev/null; then
    $SUDO apt-get update -qq > /dev/null
fi

# Install Python
if ! which python3 --version > /dev/null; then
    echo "Trying to install Python..."

    if which apt-get > /dev/null; then
        $SUDO apt-get install -qq python3 python3-six apt-utils > /dev/null && echo "Python installed!"
    elif which yum > /dev/null; then
        $SUDO yum install -y python3 python3-six > /dev/null && echo "Python installed!"
    fi

    $SUDO ln -sf /usr/bin/python3 /usr/bin/python > /dev/null
fi

# Install pip
if ! which pip > /dev/null; then
    echo "Trying to install pip..."

    if which apt-get > /dev/null; then
        $SUDO apt-get install -qq python3-pip > /dev/null && echo "pip installed!"
    elif which yum > /dev/null; then
        $SUDO yum install -y python3-pip > /dev/null && echo "pip installed!"
    fi

    $SUDO ln -sf /usr/bin/pip3 /usr/bin/pip > /dev/null
fi

# Check if python3-venv is installed, if not, install it
if ! python3 -m venv --help > /dev/null 2>&1; then
    echo "Installing python3-venv..."
    if which apt-get > /dev/null; then
        $SUDO apt-get install -qq python3-venv > /dev/null && echo "python3-venv installed!"
    elif which yum > /dev/null; then
        $SUDO yum install -y python3-venv > /dev/null && echo "python3-venv installed!"
    fi
fi

# Install wget
if ! which wget > /dev/null; then
    echo "Trying to install wget..."

    if which apt-get > /dev/null; then
        $SUDO apt-get install -qq wget > /dev/null && echo "wget installed!"
    elif which yum > /dev/null; then
        $SUDO yum install -y wget > /dev/null && echo "wget installed!"
    fi
fi

echo "Python environment setup complete!"