#!/bin/bash
# Get the Shipyard environment URL and bypass token for an environment.

ORB_VERSION=3.1.0
USER_AGENT="CircleCI (shipyard/shipyard:${ORB_VERSION})"
URL="${SHIPYARD_BASE_URL:-https://shipyard.build}"
ORG="${CIRCLE_PROJECT_USERNAME}"
REPO="${CIRCLE_PROJECT_REPONAME}"
BRANCH="${CIRCLE_BRANCH}"

# Get auth token
SHIPYARD_API_TOKEN=${!PARAM_SHIPYARD_TOKEN}
[ -z "$SHIPYARD_API_TOKEN" ] && echo "A Shipyard API token must be supplied. Check the \"api-token\" parameter." && exit 1

# Hit the Shipyard API
URL="${URL}/api/v1/environment?org_name=${ORG}&repo_name=${REPO}&branch=${BRANCH}"
JSON=$(curl -s "${URL}" -H "x-api-token: ${SHIPYARD_API_TOKEN}" -H "User-Agent: ${USER_AGENT}")

# Ensure we got a response
if [ -z "${JSON}" ]
then
  echo "ERROR: no response from ${URL}"
  exit 1
fi

# Ensure there are no other errors
if [ "$(echo "${JSON}" | jq -r '.errors[0]')" != null ]
then
  ERROR=$(echo "${JSON}" | jq -r '.errors[0].title')
  echo "ERROR: ${ERROR}."
  exit 1
fi

SHIPYARD_BYPASS_TOKEN=$(echo "${JSON}" | jq -r '.data[0].attributes.bypass_token')
SHIPYARD_ENVIRONMENT_URL=$(echo "${JSON}" | jq -r '.data[0].attributes.url')
SHIPYARD_ENVIRONMENT_READY=$(echo "${JSON}" | jq -r '.data[0].attributes.ready')
SHIPYARD_ENVIRONMENT_STOPPED=$(echo "${JSON}" | jq -r '.data[0].attributes.stopped')

# Validate the response data
if [ -z "${SHIPYARD_BYPASS_TOKEN}" ]; then
  echo "${JSON}"
  echo "ERROR: no bypass token found!"
  exit 1
fi

if [ -z "${SHIPYARD_ENVIRONMENT_URL}" ]; then
  echo "${JSON}"
  echo "ERROR: no access url found!"
  exit 1
fi

if [ -z "${SHIPYARD_ENVIRONMENT_READY}" ]; then
  echo "${JSON}"
  echo "ERROR: no value for 'ready'!"
  exit 1
fi

# Wait for the environment to be ready
while [[ "${SHIPYARD_ENVIRONMENT_READY}" != true ]]; do
  if [[ "${SHIPYARD_ENVIRONMENT_STOPPED}" == true ]]; then
    echo "${JSON}"
    echo "ERROR: environment is stopped!"
    exit 1
  fi
  echo "Waiting for your Shipyard environment..."
  sleep 15

  # Re-fetch the data
  JSON=$(curl -s "${URL}" -H "x-api-token: ${SHIPYARD_API_TOKEN}" -H "User-Agent: ${USER_AGENT}")
  SHIPYARD_BYPASS_TOKEN=$(echo "${JSON}" | jq -r '.data[0].attributes.bypass_token')
  SHIPYARD_ENVIRONMENT_URL=$(echo "${JSON}" | jq -r '.data[0].attributes.url')
  SHIPYARD_ENVIRONMENT_READY=$(echo "${JSON}" | jq -r '.data[0].attributes.ready')
  SHIPYARD_ENVIRONMENT_STOPPED=$(echo "${JSON}" | jq -r '.data[0].attributes.stopped')
done

{ echo "export SHIPYARD_BYPASS_TOKEN=${SHIPYARD_BYPASS_TOKEN}"; echo "export SHIPYARD_ENVIRONMENT_URL=${SHIPYARD_ENVIRONMENT_URL}"; echo "export SHIPYARD_ENVIRONMENT_READY=${SHIPYARD_ENVIRONMENT_READY}"; } >> "${BASH_ENV}"
