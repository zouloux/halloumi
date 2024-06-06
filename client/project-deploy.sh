#!/bin/bash

# Ensure exactly one argument is given
if [ $# -ne 1 ]; then
  echo "Usage: $0 branch"
  exit 1
fi

branch=$1
userDir="/home/$USER"

# Ensure script is run from a user directory
if [[ $PWD != $userDir ]]; then
  echo "Script must be run from a project user root."
  exit 1
fi

# Create variables
dataDir="$userDir/data"
tarFile="$userDir/artifacts/$branch.tar.gz"
buildNumber=$(openssl rand -hex 8)
destinationBuildDir="$userDir/builds/$branch-$buildNumber"
destinationBranchLink="$userDir/branches/$branch"

# Extract tar.gz file
mkdir -p $destinationBuildDir
if ! tar -xzf $tarFile -C $destinationBuildDir; then
  echo "Failed to extract $tarFile"
  rm -f $tarFile
  exit 1
fi

dotEnv="$destinationBuildDir/.env"
echo "" >> $dotEnv
echo "PASTA_BUILD=$buildNumber" >> $dotEnv

# Set the docker compose project name from the unique build number
# With this, "docker compose" commands can be ran from the branch link and the build directory
composeProjectName="$USER_$branch_$buildNumber"
echo "COMPOSE_PROJECT_NAME=$destinationBuildDir" >> $dotEnv

#echo "USER_ID=$(id -u $USER):$(id -g $USER)" >> $dotEnv

# Preparing data directories
echo "Extracting data directories ..."
dockerComposeConfig=$(cd $destinationBuildDir && docker compose config)
dataVolumes=$(echo "$dockerComposeConfig" | grep "source: $HOME/data" | awk -F"$HOME/data" '{print $2}' | tr -d ' ')

# Create directories for each volume
for volume in $dataVolumes; do
  echo "- $volume"
  mkdir -p "${dataDir}${volume}"
done

# FIXME : Maybe find something else than 777 ?
# FIXME : Adding user to the group is not enough for 776, why ?
# ADD : usermod -aG www-data $username
# REMOVE : gpasswd -d $username www-data
echo "Patching user on data ..."
chown -R "$USER:$USER" $dataDir
chmod -R 0777 $dataDir

# Docker compose up
echo "Starting containers ..."
if ! (cd $destinationBuildDir && docker compose up -d); then
  echo "⚠ Unable to start docker stack"
  rm -rf $destinationBuildDir
  rm -f $tarFile
  exit 1
fi
echo ""

# TODO : Wait enough time to have the new container ready before stopping the old one
# TODO : Maybe having a heartbeat call or something ?
# TODO : If more than 60s, docker compose down and fail
#sleep 3

echo "Stopping and removing old containers ..."
if [ -d $destinationBranchLink ]; then
  oldBranchDir=$(readlink -f $destinationBranchLink)
  (cd $oldBranchDir && docker compose down && docker container prune -f)
  rm -rf $oldBranchDir
fi
echo ""

echo "Creating branch link ..."
ln -sf $destinationBuildDir $destinationBranchLink
rm -f $tarFile

echo ""
echo "Done"
