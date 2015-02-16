#!/bin/bash

# GC project
project=$(cat settings | grep project= | head -1 | cut -f2 -d"=")
# control node name
control_name=$(cat settings | grep control_name= | head -1 | cut -f2 -d"=")
# get control node external IP
control_ip=$(gcloud compute instances list --project=$project | grep -v grep | grep $control_name | awk {'print $5'});

mkdir -p ~/k8s-bin/downloads
# download etcd and fleet clients for OS X
ETCD_RELEASE=$(ssh core@$control_ip etcdctl --version | cut -d " " -f 3- | tr -d '\r')
echo "Downloading etcdctl v$ETCD_RELEASE for OS X"
curl -L -o ~/k8s-bin/downloads/etcd.zip "https://github.com/coreos/etcd/releases/download/v$ETCD_RELEASE/etcd-v$ETCD_RELEASE-darwin-amd64.zip"
unzip -j -o "$HOME/k8s-bin/downloads/etcd.zip" "etcd-v$ETCD_RELEASE-darwin-amd64/etcdctl"
mv -f etcdctl ~/k8s-bin
echo "etcdctl was copied to ~/k8s-bin"
echo " "

#
FLEET_RELEASE=$(ssh core@$control_ip fleetctl version | cut -d " " -f 3- | tr -d '\r')
echo "Downloading fleetctl v$FLEET_RELEASE for OS X"
curl -L -o ~/k8s-bin/downloads/fleet.zip "https://github.com/coreos/fleet/releases/download/v$FLEET_RELEASE/fleet-v$FLEET_RELEASE-darwin-amd64.zip"
unzip -j -o "$HOME/k8s-bin/downloads/fleet.zip" "fleet-v$FLEET_RELEASE-darwin-amd64/fleetctl"
mv -f fleetctl ~/k8s-bin
echo "fleetctl was copied to ~/k8s-bin "
echo " "

# download kubernetes binaries for OS X
# k8s version
k8s_version=$(curl --insecure -sS https://get.k8s.io | grep release= | cut -f2 -d"=")
###$(cat bootstrap_k8s_cluster.sh | grep k8s_version= | head -1 | cut -f2 -d"=")
echo "Downloading kubernetes $k8s_version for OS X"
#wget -c http://github.com/GoogleCloudPlatform/kubernetes/releases/download/$k8s_version/kubernetes.tar.gz
curl -L -o ~/k8s-bin/downloads/kubernetes.tar.gz "https://github.com/GoogleCloudPlatform/kubernetes/releases/download/$k8s_version/kubernetes.tar.gz"
tar -xzvf ~/k8s-bin/downloads/kubernetes.tar.gz ~/k8s-bin/downloads/kubernetes/platforms/darwin/amd64
mv -f ~/k8s-bin/downloads/kubernetes/platforms/darwin/amd64/kubectl ~/k8s-bin
mv -f ~/k8s-bin/downloads/kubernetes/platforms/darwin/amd64/kubecfg ~/k8s-bin
# clean up
rm -fr ~/k8s-bin/downloads/kubernetes

echo "kubecfg and kubectl were copied to ~/k8s-bin"
echo " "
