"""
# Purpose:

Upload artifacts to JFrog Artifactory with complete Shipyard environment data
as build evidence including URLs, environment ID, and timestamps.

# Required environment variables:

- ARTIFACTORY_URL_VAR (name of env var containing Artifactory URL)
- ARTIFACTORY_USER_VAR (name of env var containing Artifactory username)
- ARTIFACTORY_APIKEY_VAR (name of env var containing Artifactory API key)
- ARTIFACTORY_REPOSITORY (target repository name)
- ARTIFACT_PATH (local path to artifact file)
- TARGET_PATH (target path in repository)
- BUILD_NAME (build name for evidence)
- BUILD_NUMBER (build number for evidence)
"""
from __future__ import print_function

import os
import sys
import json
import hashlib
import requests
from datetime import datetime


def exit_with_error(msg):
    print(f"❌ ERROR: {msg}")
    sys.exit(1)


def calculate_checksums(file_path):
    """Calculate MD5 and SHA1 checksums for the artifact file"""
    md5_hash = hashlib.md5()
    sha1_hash = hashlib.sha1()
    
    try:
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b""):
                md5_hash.update(chunk)
                sha1_hash.update(chunk)
        
        return {
            'md5': md5_hash.hexdigest(),
            'sha1': sha1_hash.hexdigest()
        }
    except Exception as e:
        exit_with_error(f"Failed to calculate checksums: {e}")


def read_shipyard_data():
    """Read complete Shipyard environment data from JSON file"""
    json_file_path = '/tmp/shipyard_environment_data.json'
    
    if not os.path.exists(json_file_path):
        print("⚠️  No Shipyard environment JSON file found - using basic environment variables only")
        return None
    
    try:
        with open(json_file_path, 'r') as f:
            data = json.load(f)
        
        print("📊 Reading Shipyard environment data from JSON file")
        print(f"Environment ID: {data.get('environment_id', 'N/A')}")
        print(f"Main URL: {data.get('environment_data', {}).get('url', 'N/A')}")
        print(f"Fetched at: {data.get('fetched_at', 'N/A')}")
        
        return data
    except Exception as e:
        print(f"⚠️  Failed to read Shipyard JSON data: {e}")
        return None


def create_build_properties(shipyard_data):
    """Create build properties including Shipyard environment data"""
    properties = {
        'circle.build.number': os.environ.get('CIRCLE_BUILD_NUM', ''),
        'circle.job': os.environ.get('CIRCLE_JOB', ''),
        'circle.workflow.id': os.environ.get('CIRCLE_WORKFLOW_ID', ''),
        'circle.pr.number': os.environ.get('CIRCLE_PR_NUMBER', ''),
    }
    
    if shipyard_data:
        env_data = shipyard_data.get('environment_data', {})
        properties.update({
            'shipyard.environment.id': shipyard_data.get('environment_id', ''),
            'shipyard.environment.url': env_data.get('url', ''),
            'shipyard.environment.ready': str(env_data.get('ready', '')),
            'shipyard.environment.retired': str(env_data.get('retired', '')),
            'shipyard.environment.fetched_at': shipyard_data.get('fetched_at', ''),
            'shipyard.environment.commit_hash': shipyard_data.get('commit_hash', ''),
        })
        
        # Add additional URLs as separate properties
        additional_urls = shipyard_data.get('additional_urls', {})
        for key, value in additional_urls.items():
            properties[f'shipyard.url.{key}'] = value
        
        # Add projects data as JSON string
        projects = env_data.get('projects', [])
        if projects:
            properties['shipyard.projects.data'] = json.dumps(projects)
    
    return properties


def upload_artifact(artifactory_url, artifactory_user, artifactory_apikey, 
                   repository, artifact_path, target_path, checksums):
    """Upload artifact to JFrog Artifactory"""
    
    full_url = f"{artifactory_url}/{repository}/{target_path}"
    
    print("📤 Uploading artifact to JFrog...")
    print(f"Source: {artifact_path}")
    print(f"Target: {full_url}")
    
    headers = {
        'X-JFrog-Art-Api': artifactory_apikey,
        'X-Checksum-Deploy': 'false',
        'X-Checksum-Sha1': checksums['sha1'],
        'X-Checksum-Md5': checksums['md5']
    }
    
    try:
        with open(artifact_path, 'rb') as f:
            response = requests.put(
                full_url,
                auth=(artifactory_user, artifactory_apikey),
                headers=headers,
                data=f,
                timeout=300
            )
        
        if response.status_code in [200, 201]:
            print("✅ Artifact uploaded successfully!")
            return True
        else:
            print(f"❌ Upload failed with HTTP code: {response.status_code}")
            print(f"Response: {response.text}")
            return False
            
    except Exception as e:
        exit_with_error(f"Failed to upload artifact: {e}")


def upload_build_info(artifactory_url, artifactory_user, artifactory_apikey,
                     build_name, build_number, target_path, checksums, properties):
    """Upload build information to JFrog Artifactory"""
    
    build_info = {
        "version": "1.0.1",
        "name": build_name,
        "number": build_number,
        "type": "GENERIC",
        "buildAgent": {
            "name": "CircleCI",
            "version": "2.1"
        },
        "agent": {
            "name": "shipyard-orb",
            "version": "1.0.0"
        },
        "started": datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%fZ')[:-3] + 'Z',
        "durationMillis": 0,
        "principal": os.environ.get('CIRCLE_USERNAME', 'circleci'),
        "artifactoryPrincipal": artifactory_user,
        "url": os.environ.get('CIRCLE_BUILD_URL', ''),
        "vcs": {
            "revision": os.environ.get('CIRCLE_SHA1', ''),
            "url": os.environ.get('CIRCLE_REPOSITORY_URL', '')
        },
        "modules": [
            {
                "id": build_name,
                "artifacts": [
                    {
                        "type": target_path.split('.')[-1] if '.' in target_path else 'generic',
                        "sha1": checksums['sha1'],
                        "md5": checksums['md5'],
                        "name": os.path.basename(target_path),
                        "path": target_path
                    }
                ]
            }
        ],
        "properties": properties
    }
    
    build_info_url = f"{artifactory_url}/api/build"
    
    print("📋 Uploading build evidence...")
    
    try:
        response = requests.put(
            build_info_url,
            auth=(artifactory_user, artifactory_apikey),
            headers={'Content-Type': 'application/json'},
            json=build_info,
            timeout=60
        )
        
        if response.status_code in [200, 204]:
            print("✅ Build evidence uploaded successfully!")
            print(f"Build Name: {build_name}")
            print(f"Build Number: {build_number}")
            return True
        else:
            print(f"⚠️  Build evidence upload failed with HTTP code: {response.status_code}")
            print(f"Response: {response.text}")
            print("Artifact was uploaded but build evidence failed")
            return False
            
    except Exception as e:
        print(f"⚠️  Failed to upload build evidence: {e}")
        print("Artifact was uploaded but build evidence failed")
        return False


def main():
    """Main function to orchestrate the JFrog upload process"""
    
    # Get credentials from environment variables
    artifactory_url_var = os.environ.get('ARTIFACTORY_URL_VAR')
    artifactory_user_var = os.environ.get('ARTIFACTORY_USER_VAR')
    artifactory_apikey_var = os.environ.get('ARTIFACTORY_APIKEY_VAR')
    
    if not all([artifactory_url_var, artifactory_user_var, artifactory_apikey_var]):
        exit_with_error("Missing credential environment variable names")
    
    artifactory_url = os.environ.get(artifactory_url_var)
    artifactory_user = os.environ.get(artifactory_user_var)
    artifactory_apikey = os.environ.get(artifactory_apikey_var)
    
    # Get required parameters
    repository = os.environ.get('ARTIFACTORY_REPOSITORY')
    target_path = os.environ.get('TARGET_PATH')
    build_name = os.environ.get('BUILD_NAME')
    build_number = os.environ.get('BUILD_NUMBER')
    
    # Fixed artifact path - always upload Shipyard environment data
    artifact_path = '/tmp/shipyard_environment_data.json'
    
    # Validate required parameters
    if not all([artifactory_url, repository, target_path]):
        exit_with_error("Missing required parameters: ARTIFACTORY_URL, ARTIFACTORY_REPOSITORY, TARGET_PATH")
    
    if not all([artifactory_user, artifactory_apikey]):
        exit_with_error("Artifactory credentials not found in environment variables")
    
    # Check if Shipyard data exists, create minimal data if not
    if not os.path.exists(artifact_path):
        print("⚠️  No Shipyard environment data found - creating minimal build data")
        minimal_data = {
            "project": os.environ.get('CIRCLE_PROJECT_REPONAME', 'unknown'),
            "build": os.environ.get('CIRCLE_BUILD_NUM', '1'),
            "commit": os.environ.get('CIRCLE_SHA1', ''),
            "branch": os.environ.get('CIRCLE_BRANCH', ''),
            "build_url": os.environ.get('CIRCLE_BUILD_URL', ''),
            "created_at": datetime.utcnow().isoformat() + 'Z'
        }
        with open(artifact_path, 'w') as f:
            json.dump(minimal_data, f, indent=2)
    
    # Set default values
    build_name = build_name or os.environ.get('CIRCLE_PROJECT_REPONAME', 'unknown')
    build_number = build_number or os.environ.get('CIRCLE_BUILD_NUM', '1')
    
    print(f"🚀 Starting JFrog upload process...")
    print(f"Repository: {repository}")
    print(f"Build: {build_name} #{build_number}")
    
    # Calculate checksums
    checksums = calculate_checksums(artifact_path)
    
    # Read Shipyard environment data
    shipyard_data = read_shipyard_data()
    
    # Create build properties
    properties = create_build_properties(shipyard_data)
    
    # Upload artifact
    if not upload_artifact(artifactory_url, artifactory_user, artifactory_apikey,
                          repository, artifact_path, target_path, checksums):
        sys.exit(1)
    
    # Upload build information
    upload_build_info(artifactory_url, artifactory_user, artifactory_apikey,
                     build_name, build_number, target_path, checksums, properties)
    
    print("🎉 Upload process completed!")


if __name__ == "__main__":
    main()