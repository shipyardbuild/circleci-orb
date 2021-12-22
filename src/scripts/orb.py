"""
# Purpose:

Wait for the Shipyard environment to be ready,
then put its data in the environment.

# Required environment variables:

- BASH_ENV
- CIRCLE_PROJECT_USERNAME
- CIRCLE_PROJECT_REPONAME
- CIRCLE_PROJECT_BRANCH
- SHIPYARD_API_TOKEN
"""
from __future__ import print_function

import os
import sys
import time

import swagger_client
from swagger_client.rest import ApiException


def exit(msg):
    print(msg)
    sys.exit(1)


# Make sure there's a bash env file in the environment
bash_env_path = os.environ.get('BASH_ENV')
if not bash_env_path:
    exit('ERROR: missing BASH_ENV environment variable')

# Constants
org_name = os.environ.get("CIRCLE_PROJECT_USERNAME")
repo = os.environ.get("CIRCLE_PROJECT_REPONAME")
branch = os.environ.get("CIRCLE_BRANCH")

# Get auth token
api_token = os.environ.get('SHIPYARD_API_TOKEN')
if not api_token:
    exit('No SHIPYARD_API_TOKEN provided, exiting.')

# Prepare API client
configuration = swagger_client.Configuration()
configuration.api_key['x-api-token'] = api_token
client = swagger_client.ApiClient(configuration)
api_instance = swagger_client.EnvironmentApi(client)


def fetch_shipyard_environment():
    """Fetch the Shipyard environment for this CircleCI job"""

    # Hit the Shipyard API
    try:
        response = api_instance.list_environments(org_name=org_name,
                                                  repo_name=repo,
                                                  branch=branch).to_dict()
    except ApiException as e:
        exit("ERROR: issue while listing environments via API: {}".format(e))

    # Exit if any errors
    errors = response.get('errors')
    if errors:
        exit('ERROR: {}'.format(errors[0]["title"]))

    # Verify an environment was found
    if not len(response['data']):
        exit('ERROR: no matching Shipyard environment found')

    # Verify the data is where we expect
    try:
        environment_id = response['data'][0]['id']
        environment_data = response['data'][0]['attributes']
    except Exception:
        exit('ERROR: invalid response data structure')

    # Verify all the needed fields are available
    for param in ('bypass_token', 'url', 'ready', 'stopped', 'retired'):
        if param not in environment_data:
            exit('ERROR: no {} found!'.format(param))

    return environment_id, environment_data


def restart_environment(environment_id):
    """Restart the Shipyard environment with the provided ID"""

    try:
        api_instance.restart_environment(environment_id)
    except ApiException as e:
        exit("ERROR: issue while restart the environment: {}".format(e))


def wait_for_environment():
    """Return the Shipyard environment data once it's ready"""

    auto_restart = True
    was_restarted = False

    # Check the environment
    environment_id, environment_data = fetch_shipyard_environment()

    # Until the environment is ready
    while not environment_data['ready']:
        # Auto-restart the environment once if indicated
        if all([environment_data['retired'], auto_restart, not was_restarted]):
            restart_environment(environment_id)
            was_restarted = True
            print('Restarted Shipyard environment...')
        elif environment_data['stopped'] and not environment_data['processing']:
            exit('ERROR: this environment is stopped and no builds are processing')

        # Wait 15 seconds
        print("Waiting for Shipyard environment...")
        time.sleep(15)

        # Check on the environment again
        environment_id, environment_data = fetch_shipyard_environment()

    return environment_id, environment_data


def main():
    """
    Wait for the Shipyard environment to be ready,
    then put it's data in the bash environment.
    """

    _, environment_data = wait_for_environment()

    # Write the data to the job's environment
    with open(bash_env_path, 'a') as bash_env:
        bash_env.write('\n'.join([
            'export SHIPYARD_BYPASS_TOKEN={}'.format(environment_data["bypass_token"]),
            'export SHIPYARD_ENVIRONMENT_URL={}'.format(environment_data["url"]),
            'export SHIPYARD_ENVIRONMENT_READY={}'.format(environment_data["ready"]),
        ]))

    print('Shipyard environment data written to {}!'.format(bash_env_path))


if __name__ == "__main__":
    main()