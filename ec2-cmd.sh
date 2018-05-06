#!/bin/bash

if [ "$#" -lt 2 ] ; then
  echo "Usage: $0 user command"
fi

#TODO: Add custom hosts eg in file
#TODO: Add options ; since this is most likely to be used as a utility within larger script, it might be better to simply add a file to use as config (-F) and specify the stuff there

ssh_user="$1"
shift

ssh_opts=''
ssh_opts+='-o ConnectTimeout 15'
ssh_opts+='-o KbdInteractiveAuthentication no'
ssh_opts+='-o BatchMode yes'
ssh_opts+='-o StrictHostKeyChecking no'
ssh_opts+='-o UserKnownHostsFile=/dev/null'

(
for reg in \
    $(aws ec2 describe-regions | jq '.Regions[].RegionName' | tr -d '"') ; do

  for ip in $(aws ec2 describe-instances --region="${reg}" \
      | jq '.Reservations[].Instances[]' | jq -c '"\(.PublicIpAddress)"' \
      | grep -v '"null"' | tr -d '"') ; do
    (
    ssh_string="ssh ${ssh_opts} ${ssh_user}@${ip} $@"
    echo "Running: ${ssh_string}..."
    eval "${ssh_string}"
    echo "Job complete [$?]: ${ssh_string}"
    ) &

  done

  wait
done
) &

wait

