#!/bin/bash
# This script is used to join one or more nodes as agents
set -x
echo $@
hostname=`hostname -f`
mkdir -p /etc/rancher/rke2
cat <<EOF >>/etc/rancher/rke2/config.yaml
server: https://${3}:9345
token:  "${4}"
node-name: "${hostname}"
cloud-provider-name:  "aws"
EOF

if [ ! -z "${8}" ] && [[ "${8}" == *":"* ]]
then
   echo "${8}"
   echo -e "${8}" >> /etc/rancher/rke2/config.yaml
   cat /etc/rancher/rke2/config.yaml
fi

if [[ ${1} == *"rhel"* ]]
then
   subscription-manager register --auto-attach --username=${9} --password=${10}
   subscription-manager repos --enable=rhel-7-server-extras-rpms
fi

if [ ${1} = "centos8" ] || [ ${1} = "rhel8" ]
then
  yum install tar -y
  yum install iptables -y
fi

if [ ${7} = "rke2" ]
then
   if [ ${6} != "null" ]
   then
       curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=${5} INSTALL_RKE2_CHANNEL=${6} INSTALL_RKE2_TYPE='agent' sh -
   else
       curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=${5} INSTALL_RKE2_TYPE='agent' sh -
   fi
   if [ ! -z "${8}" ] && [[ "${8}" == *"cis"* ]]
   then
       if [[ ${1} == *"rhel"* ]] || [[ ${1} == *"centos"* ]]
       then
           cp -f /usr/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf
       else
           cp -f /usr/local/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf
       fi
       systemctl restart systemd-sysctl
       useradd -r -c "etcd user" -s /sbin/nologin -M etcd
   fi
   sudo systemctl enable rke2-agent
   sudo systemctl start rke2-agent
else
   curl -sfL https://get.rancher.io | INSTALL_RANCHERD_VERSION=${5} INSTALL_RKE2_TYPE='agent' sh -
   sudo systemctl enable rancherd-agent
   sudo systemctl start rancherd-agent
fi
