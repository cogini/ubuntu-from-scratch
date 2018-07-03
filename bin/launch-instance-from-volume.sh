#!/bin/bash

# Create a snapshot from a volume, create an AMI, then launch an instance from it

set -e

VOLUME_ID=vol-09f3cd97b400288a9
SECURITY_GROUP=sg-94bafcec

TAG_OWNER=jake

getVolumeIdentifier() {
  aws ec2 describe-instances \
    --instance-id $1 \
    --query 'Reservations[0].Instances[0].BlockDeviceMappings[?DeviceName==`/dev/sdb`].Ebs[].VolumeId' \
    --output text
}

waitForInstanceState() {
  while [ ! $( aws ec2 describe-instances \
                 --instance-id $1 \
                 --query Reservations[0].Instances[0].State.Name \
                 --output text) = $2 ]
    do sleep 5
  done
}

waitForSnapshotState() {
  while [ ! $( aws ec2 describe-snapshots \
                 --snapshot-id $1 \
                 --query Snapshots[0].State \
                 --output text) = $2 ]
    do sleep 5
  done
}

getInstanceIp() {
  aws ec2 describe-instances \
    --instance-id $1 \
    --query 'Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicIp' \
    --output text
}

waitForConsoleOutput() {
  CONSOLE_OUTPUT=$( aws ec2 get-console-output \
      --instance-id "$INSTANCE_ID" \
     --query 'Output' --output text)
  while [ "$CONSOLE_OUTPUT" = "None" ]
    do sleep 5
  done
  echo "$CONSOLE_OUTPUT"
}

# https://docs.aws.amazon.com/cli/latest/reference/ec2/create-snapshot.html

echo "Creating snapshot of volume $VOLUME_ID"
SNAPSHOT_ID=$( aws ec2 create-snapshot \
    --volume-id "$VOLUME_ID" \
    --description 'Volume for AMI' \
    --query 'SnapshotId' --output text)

waitForSnapshotState "$SNAPSHOT_ID" 'completed'

echo "Registering image with snapshot $SNAPSHOT_ID"
IMAGE_ID=$(aws ec2 register-image --architecture x86_64 \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=true,SnapshotId=$SNAPSHOT_ID,VolumeSize=1,VolumeType=gp2}" \
    --name "ubuntu-from-scratch simple network $SNAPSHOT_ID" --root-device-name /dev/sda1 --virtualization-type hvm \
    --query 'ImageId' --output text)


echo "Starting instance with AMI $IMAGE_ID"
INSTANCE_ID=$(aws ec2 run-instances --image-id "$IMAGE_ID" --instance-type t2.micro --key-name cogini-jake \
    --associate-public-ip-address --security-group-ids $SECURITY_GROUP \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ubuntu-from-scratch},{Key=owner,Value=jake}]' \
    --query Instances[0].InstanceId --output text)

waitForInstanceState "$INSTANCE_ID" "running"

INSTANCE_IP=$(aws ec2 describe-instances --instance-id "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicIp' --output text)

echo "Instance public IP: $INSTANCE_IP"
# echo "AMI: $IMAGE_ID"
# echo "InstanceId: $INSTANCE_ID"
# echo "Instance IP: $INSTANCE_IP"

echo "aws ec2 get-console-output --instance-id "$INSTANCE_ID" --query 'Output' --output text"

# waitForConsoleOutput
