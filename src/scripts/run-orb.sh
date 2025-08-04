#!/usr/bin/env sh

# Activate the virtual environment
. /tmp/orb_env/bin/activate

# Change to the directory where orb.py is located
cd /tmp/circleci-orb-feat-jfrog-integration/src/scripts || exit

# Run the orb
python orb.py