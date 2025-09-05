#!/usr/bin/env sh
ls /tmp -la
BRANCH_NAME=feat/jfrog-integration

# Convert branch name to archive filename format (replace / with -)
ARCHIVE_NAME=$(echo "${BRANCH_NAME}" | sed 's/\//-/g')

# Download the orb (for dependencies only)
cd /tmp || exit

if ! wget -q "https://github.com/shipyardbuild/circleci-orb/archive/refs/heads/${BRANCH_NAME}.tar.gz" -O "${ARCHIVE_NAME}.tar.gz"; then
    echo "Failed to download orb from GitHub"
    exit 1
fi
ls -la
if ! tar xvzf "${ARCHIVE_NAME}.tar.gz" > /dev/null; then
    echo "Failed to extract orb archive"
    exit 1
fi
ls -la
cd "/tmp/circleci-orb-${ARCHIVE_NAME}/src/scripts" || exit

# Create a virtual environment
if ! python3 -m venv /tmp/orb_env; then
    echo "Failed to create virtual environment"
    exit 1
fi

# Activate the virtual environment
# shellcheck disable=SC1091
. /tmp/orb_env/bin/activate

# Install the required packages
pip install -r requirements.txt > /dev/null