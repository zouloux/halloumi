#!/bin/bash
if [ $# -lt 1 ]; then
  echo "Usage: $0 file ..."
  exit 1
fi
currentUser=$(whoami)
sshPort=$(grep -E "^Port" /etc/ssh/sshd_config | awk '{print $2}' || echo "22")
sshHostname=$HALLOUMI_DOMAIN
currentDir=$(pwd)
remoteFilePath=${1}
# Generate rsync command for download with no override
echo "rsync -avz --ignore-existing --itemize-changes -e 'ssh -p $sshPort' $currentUser@$sshHostname:$currentDir/$remoteFilePath ."