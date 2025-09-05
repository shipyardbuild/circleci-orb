#!/usr/bin/env sh

# Activate the virtual environment
. /tmp/orb_env/bin/activate

# Change to the directory where jfrog_upload.py is located
cd /tmp/circleci-orb-feat-jfrog-integration/src/scripts || exit

# Run the JFrog upload script
python jfrog_upload.py