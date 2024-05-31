#!/bin/bash
currentUser=$(whoami)
sshPort=$(grep -E "^Port" /etc/ssh/sshd_config | awk '{print $2}' || echo "22")
sshHostname=$HALLOUMI_DOMAIN
currentDir=$(pwd)
localFilePath=${1:-<local_file_path>}
# Generate rsync command with no override
echo "rsync -avz --ignore-existing --itemize-changes -e 'ssh -p $sshPort' $localFilePath $currentUser@$sshHostname:$currentDir"