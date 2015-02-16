#!/bin/bash -x

# Update required settings in "settings" file
# GC settings

# project and zone
project=$(cat settings | grep project= | head -1 | cut -f2 -d"=")
zone=$(cat settings | grep zone= | head -1 | cut -f2 -d"=")

# CoreOS release channel
channel=$(cat settings | grep channel= | head -1 | cut -f2 -d"=")

# control, k8s master and node types
control_machine_type=$(cat settings | grep control_machine_type= | head -1 | cut -f2 -d"=")
k8s_master_machine_type=$(cat settings | grep k8s_master_machine_type= | head -1 | cut -f2 -d"=")
node_machine_type=$(cat settings | grep node_machine_type= | head -1 | cut -f2 -d"=")
##

###
# etcd control name
control_name=project=$(cat settings | grep control_name= | head -1 | cut -f2 -d"=")
# k8s master name
master_name=$(cat settings | grep master_name= | head -1 | cut -f2 -d"=")
# node name
node_name=project=$(cat settings | grep node_name= | head -1 | cut -f2 -d"=")
###

# get the latest full image name
image=$(gcloud compute images list | grep -v grep | grep coreos-$channel | awk {'print $1'})

# update cloud-configs with CoreOS release channel
sed -i "" -e 's/GROUP/'$channel'/g' ./cloud-config/*.yaml
# update fleet units with k8s version
sed -i "" -e 's/k8s_version/'$k8s_version'/g' ./fleet-units/*.service
#

# CONTROL
# create control node
gcloud compute instances create $control_name \
--project=$project --image=$image --image-project=coreos-cloud \
--boot-disk-type=pd-ssd --boot-disk-size=10 --zone=$zone \
--machine-type=$control_machine_type --metadata-from-file user-data=./cloud-config/control.yaml \
--can-ip-forward --scopes compute-rw --tags k8s-cluster

# get control node internal IP
control_node_ip=$(gcloud compute instances list --project=$project | grep -v grep | grep $control_name | awk {'print $4'});

# K8S MASTER
# create k8s master
# update master's cloud-config with control node's internal IP
sed -i "" -e 's/CONTROL-NODE-INTERNAL-IP/'$control_node_ip'/g' ./cloud-config/master.yaml
gcloud compute instances create $master_name \
--project=$project --image=$image --image-project=coreos-cloud \
--boot-disk-type=pd-ssd --boot-disk-size=10 --zone=$zone \
--machine-type=$master_machine_type --metadata-from-file user-data=./cloud-config/control.yaml \
--can-ip-forward --scopes compute-rw --tags k8s-cluster

# get master external IP
master_node_ip=$(gcloud compute instances list --project=$project | grep -v grep | grep $master_name | awk {'print $4'});

# NODES
# update node's cloud-config with control node's internal IP
sed -i "" -e 's/CONTROL-NODE-INTERNAL-IP/'$control_node_ip'/g' ./cloud-config/node.yaml
# create nodes
#  by defaul it creates two nodes
gcloud compute instances create $node_name-01 $node_name-02 \
--project=$project --image=$image --image-project=coreos-cloud \
--boot-disk-type=pd-ssd --boot-disk-size=20 --zone=$zone \
--machine-type=$node_machine_type --metadata-from-file user-data=./cloud-config/node.yaml \
--can-ip-forward --tags k8s-cluster

# FLEET
# update fleet units with control node's internal IP
sed -i "" -e 's/CONTROL-NODE-INTERNAL-IP/'$control_node_ip'/g' ./fleet-units/*.service

# download etcdctl, fleetctl and k8s binaries for OS X
./get_k8s_fleet_etcd_osx.sh

# set binaries folder, fleet tunnel to control's external IP
export PATH=${HOME}/k8s-bin:$PATH
control_external_ip=$(gcloud compute instances list --project=$project | grep -v grep | grep $control_name | awk {'print $5'});
export FLEETCTL_TUNNEL="$control_external_ip"
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false

# deploy k8s fleet units
cd ./fleet-units
echo "Installing k8s fleet units !!!"
fleetctl start kube-kubelet.service 
fleetctl start kube-proxy.service
fleetctl start kube-apiserver.service
fleetctl start kube-controller-manager.service
fleetctl start kube-scheduler.service
fleetctl start kube-register.service
echo " "
fleetctl list-units
