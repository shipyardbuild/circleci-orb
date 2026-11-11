"""
# Purpose:

Wait for the Shipyard environment to be ready,
then put its data in the environment.

# Required environment variables:

- BASH_ENV
- CIRCLE_PROJECT_USERNAME
- CIRCLE_PROJECT_REPONAME
- CIRCLE_BRANCH
- SHIPYARD_API_TOKEN
- SHIPYARD_TIMEOUT
"""
from __future__ import print_function

import json
import os
import re
import sys
import time
from datetime import datetime, timedelta, timezone
from functools import wraps

import swagger_client
from swagger_client.rest import ApiException


def retry_on_failure(max_retries=3, delay=5):
    """Decorator to retry a function on failure with exponential backoff"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            last_exception = None
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    last_exception = e
                    if attempt < max_retries - 1:  # Don't log on the last attempt
                        wait_time = delay * (2 ** attempt)  # Exponential backoff
                        log_with_timestamp(f"Attempt {attempt + 1} failed: {e}. Retrying in {wait_time} seconds...")
                        time.sleep(wait_time)
                    else:
                        log_with_timestamp(f"All {max_retries} attempts failed. Last error: {e}")
            raise last_exception
        return wrapper
    return decorator


def log_with_timestamp(msg):
    """Print a message with UTC timestamp prefix"""
    timestamp = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')
    print(f"[{timestamp}] {msg}")


def exit_with_error(msg):
    log_with_timestamp(msg)
    # Clean up the thread pool before exiting
    if 'client' in globals() and client and hasattr(client, 'pool'):
        client.pool.close()
        client.pool.join()
    sys.exit(1)


# Make sure there's a bash env file in the environment
bash_env_path = os.environ.get('BASH_ENV')
if not bash_env_path:
    exit_with_error('ERROR: missing BASH_ENV environment variable')

# Constants
repo_owner = os.environ.get("CIRCLE_PROJECT_USERNAME")
repo = os.environ.get("CIRCLE_PROJECT_REPONAME")
branch = os.environ.get("CIRCLE_BRANCH")

# Get auth token
api_token = os.environ.get('SHIPYARD_API_TOKEN')
if not api_token:
    exit_with_error('No SHIPYARD_API_TOKEN provided, exiting.')

# Get the timeout
timeout_minutes = os.environ.get('SHIPYARD_TIMEOUT')
try:
    timeout_minutes = int(timeout_minutes)
except Exception:
    exit_with_error('ERROR: the SHIPYARD_TIMEOUT provided ("{}") is not an integer'.format(timeout_minutes))

app_name = os.environ.get('SHIPYARD_APP_NAME')

# Prepare API client
configuration = swagger_client.Configuration()
configuration.api_key['x-api-token'] = api_token
client = swagger_client.ApiClient(configuration)
api_instance = swagger_client.EnvironmentApi(client)


@retry_on_failure(max_retries=3, delay=5)
def fetch_shipyard_environment():
    """Fetch the Shipyard environment for this CircleCI job"""

    # Hit the Shipyard API
    try:
        args = {
            "repo_owner": repo_owner,
            "repo_name": repo,
            "branch": branch
        }
        if app_name:
            args["name"] = app_name
        response = api_instance.list_environments(**args).to_dict()
        log_with_timestamp(f"Response: {response}")
    except ApiException as e:
        # Re-raise the exception to be handled by the retry decorator
        raise Exception("ERROR: issue while listing environments via API: {}".format(e))

    # Exit if any errors
    errors = response.get('errors')
    if errors:
        exit_with_error('ERROR: {}'.format(errors[0]["title"]))

    # Verify an environment was found
    if not len(response['data']):
        exit_with_error('ERROR: no matching Shipyard environment found')

    # Verify the data is where we expect
    try:
        environment_id = response['data'][0]['id']
        environment_data = response['data'][0]['attributes']
    except Exception:
        exit_with_error('ERROR: invalid response data structure')

    # Verify all the needed fields are available
    for param in ('bypass_token', 'url', 'ready', 'stopped', 'retired'):
        if param not in environment_data:
            exit_with_error('ERROR: no {} found!'.format(param))

    return environment_id, environment_data


def restart_environment(environment_id):
    """Restart the Shipyard environment with the provided ID"""

    try:
        api_instance.restart_environment(environment_id)
    except ApiException as e:
        exit_with_error("ERROR: issue while restart the environment: {}".format(e))


def wait_for_environment():
    """Return the Shipyard environment data once it's ready"""

    auto_restart = True
    was_restarted = False

    # Check the environment
    try:
        environment_id, environment_data = fetch_shipyard_environment()
    except Exception as e:
        exit_with_error(str(e))

    start = datetime.now()
    timeout_end = datetime.now() + timedelta(minutes=timeout_minutes)

    # Until the environment is ready
    while not environment_data['ready']:
        now = datetime.now()
        # Check if the timeout has elapsed
        if datetime.now() > timeout_end:
            exit_with_error('{} minute timeout elapsed, exiting!'.format(timeout_minutes))

        # Auto-restart the environment once if indicated
        if all([environment_data['retired'], auto_restart, not was_restarted]):
            restart_environment(environment_id)
            was_restarted = True
            log_with_timestamp('Restarted Shipyard environment...')
        elif environment_data['stopped'] and not environment_data['processing']:
            exit_with_error('ERROR: this environment is stopped and no builds are processing')

        # Wait 15 seconds
        seconds_waited = int((now - start).total_seconds())
        wait_string = ' ({}s elapsed)'.format(seconds_waited) if seconds_waited else ''
        log_with_timestamp("Waiting for Shipyard environment...{}".format(wait_string))
        time.sleep(15)

        # Check on the environment again
        try:
            environment_id, environment_data = fetch_shipyard_environment()
        except Exception as e:
            exit_with_error(str(e))

    return environment_id, environment_data


def domain_env_name(service_name):
    """SHIPYARD_DOMAIN_<NAME> for a service: uppercased, non-alphanumerics as _."""
    return 'SHIPYARD_DOMAIN_' + re.sub(r'[^A-Z0-9]', '_', service_name.upper())


def fetch_additional_urls(environment_id):
    """Per-service URLs of the environment, as {service_name: url}.

    The list endpoint leaves additional_urls out, so read them from the
    single-environment endpoint. Read the raw JSON: the generated client's
    models drop fields they don't know about. On failure, log and return {}
    so the main URL and token are still exported.
    """
    try:
        response = api_instance.get_environment(environment_id, _preload_content=False)
        body = json.loads(response.data)
        urls = body['data']['attributes'].get('additional_urls') or {}
        if not isinstance(urls, dict):
            raise ValueError('additional_urls is not an object')
        return urls
    except Exception as e:
        reason = (str(e).splitlines() or [type(e).__name__])[0]
        log_with_timestamp('WARNING: could not read the environment\'s additional URLs: {}'.format(reason))
        return {}


def main():
    """
    Wait for the Shipyard environment to be ready,
    then put it's data in the bash environment.
    """

    environment_id, environment_data = wait_for_environment()

    try:
        commit_hash = None
        # Try to fetch the commit hash of classic environments
        projects = environment_data.get('projects')
        # Filter project with non-null pull_request_number
        filtered_projects = [item for item in projects if item["pull_request_number"] is not None]
        pr_project = None
        if filtered_projects:
            pr_project = filtered_projects[0]
        else:
            pr_project = projects[0] if projects else {}
        commit_hash = pr_project.get("commit_hash")
    except Exception:
        log_with_timestamp('WARNING: unable to retrieve commit hash')
        commit_hash = None


    additional_urls = fetch_additional_urls(environment_id)
    shipyard_additional_urls_vars = [
        f'export {domain_env_name(k)}={v}' for (k, v) in sorted(additional_urls.items())
    ]
    if additional_urls:
        log_with_timestamp('Additional URLs: ' + ', '.join(domain_env_name(k) for k in sorted(additional_urls)))

    # Write the data to the job's environment
    with open(bash_env_path, 'a') as bash_env:
        bash_env.write('\n'.join([
            'export SHIPYARD_BYPASS_TOKEN={}'.format(environment_data["bypass_token"]),
            'export SHIPYARD_ENVIRONMENT_URL={}'.format(environment_data["url"]),
            'export SHIPYARD_ENVIRONMENT_ID={}'.format(environment_id),
            'export SHIPYARD_ENVIRONMENT_READY={}'.format(environment_data["ready"]),
            'export SHIPYARD_ENVIRONMENT_RETIRED={}'.format(environment_data["retired"]),
            'export SHIPYARD_DOMAIN={}'.format(environment_data["url"]),
        ] + (['export SHIPYARD_ENVIRONMENT_COMMIT_HASH={}'.format(commit_hash)] if commit_hash else [])
        + shipyard_additional_urls_vars
        ))

    log_with_timestamp(f'Shipyard environment {environment_id} data written to {bash_env_path}!')


if __name__ == "__main__":
    try:
        main()
    finally:
        # Always clean up the thread pool to prevent hanging
        if 'client' in globals() and client and hasattr(client, 'pool'):
            client.pool.close()
            client.pool.join()
