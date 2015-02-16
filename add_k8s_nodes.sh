#!/bin/bash -x

# add an extra node
# GC settings

# project and zone
project=$(cat settings | grep project= | head -1 | cut -f2 -d"=")
zone=$(cat settings | grep zone= | head -1 | cut -f2 -d"=")

# CoreOS release channel
channel=$(cat settings | grep channel= | head -1 | cut -f2 -d"=")

# etcd control name
control_name=project=$(cat settings | grep control_name= | head -1 | cut -f2 -d"=")
# node name
node_name=project=$(cat settings | grep node_name= | head -1 | cut -f2 -d"=")
###

# node types
node_machine_type=$(cat settings | grep node_machine_type= | head -1 | cut -f2 -d"=")
##

# get the latest full image name
image=$(gcloud compute images list | grep -v grep | grep coreos-$channel | awk {'print $1'})

# get control external IP
control_node_ip=$(gcloud compute instances list --project=$project | grep -v grep | grep $control_name | awk {'print $4'});

# create an extra node
#  by defaul it creates two nodes, e.g. to add a third one, add after '$node_name-02' $node_name-03 and so on
gcloud compute instances create $node_name-"$1" \
--project=$project --image=$image --image-project=coreos-cloud \
--boot-disk-type=pd-ssd --boot-disk-size=20 --zone=$zone \
--machine-type=$node_machine_type --metadata-from-file user-data=./cloud-config/node.yaml \
--can-ip-forward --tags k8s-cluster

# set binaries folder, fleet tunnel to control's external IP
export PATH=${HOME}/k8s-bin:$PATH
control_external_ip=$(gcloud compute instances list --project=$project | grep -v grep | grep $control_name | awk {'print $5'});
export FLEETCTL_TUNNEL="$control_external_ip"
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false

# list machines
echo "List of CoreOS cluster machines:"
fleetctl list-machines
echo " "

echo "List of CoreOS cluster units:"
fleetctl list-units
