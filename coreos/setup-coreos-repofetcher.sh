#!/bin/bash


setup_environment () {
  docker pull quay.io/coreos/fcct
  sudo dnf -y module install virt
  sudo dnf -y install virt-install virt-viewer libguestfs-tools
  sudo systemctl enable libvirtd.service
  sudo systemctl start libvirtd.service
  sudo systemctl status libvirtd.service
  sudo cp /registry/images/fedora-coreos-32.20201004.3.0-openstack.x86_64.qcow2 /var/lib/libvirt/images/
  sudo cp /registry/images/fedora-coreos-33.20210314.3.0-openstack.x86_64.qcow2 /var/lib/libvirt/images/
  sudo usermod -a -G libvirt $(whoami)
  sudo sed -i 's/.*unix_sock_group.*/unix_sock_group="libvirt"/g' /etc/libvirt/libvirtd.conf
  sudo sed -i 's/.*unix_sock_rw_perms.*/unix_sock_rw_perms="0770"/g' /etc/libvirt/libvirtd.conf
  sudo systemctl enable --now serial-getty@ttyS0.service
}

transmute_ignition_file () {
  echo "COPY coreos-ignition.ign to coreos-ignition-2.3.ign"
  echo "REPLACE 3.0.0 with 2.3.0"
  sed 's/3.0.0/2.3.0/g' coreos-ignition.ign > coreos-ignition-2.3.ign
}

generate_instances () {
  cat coreos-ignition.yaml.template | sed "s|<<SSH_PUBKEY>>|'`cat ~/.ssh/pubkeys/id_rsa.pub`'|g" > coreos-ignition.yaml
  docker run -i --rm quay.io/coreos/fcct --pretty --strict < coreos-ignition.yaml > coreos-ignition.ign
  transmute_ignition_file
  cp coreos-ignition-2.3.ign /tmp/coreos-ignition-2.3.ign
  sudo chmod 1777 /tmp/
  chmod 775 /tmp/coreos-ignition-2.3.ign

#  sudo virt-install -n fcos-32 --vcpus 2 -r 2048 --os-variant=fedora32 --import --network bridge=virbr0 --disk=/var/lib/libvirt/images/fedora-coreos-32.20201004.3.0-openstack.x86_64.qcow2,format=qcow2,bus=virtio --noautoconsole --qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=/tmp/coreos-ignition-2.3.ign"
  sudo virt-install -n fcos-32 --vcpus 2 -r 2048 --os-variant=fedora32 --import --network bridge=virbr0 --disk=/var/lib/libvirt/images/fedora-coreos-32.20201004.3.0-openstack.x86_64.qcow2,format=qcow2,bus=virtio --graphics=none --qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=/tmp/coreos-ignition-2.3.ign"
  qemu-kvm -m 2048 -cpu host -nographic -snapshot \
	-drive if=virtio,file=/var/lib/libvirt/images/fedora-coreos-32.20201004.3.0-openstack.x86_64.qcow2 \
	-fw_cfg name=opt/com.coreos/config,file=/tmp/coreos-ignition-2.3.ign \
	-nic user,model=virtio,hostfwd=tcp::2222-:22
#  sudo virt-install -n fcos-33 --vcpus 2 -r 2048 --os-variant=fedora33 --import --network bridge=virbr0 --disk=/var/lib/libvirt/images/fedora-coreos-33.20210314.3.0-openstack.x86_64.qcow2,format=qcow2,bus=virtio --noautoconsole --qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=/tmp/coreos-ignition-2.3.ign"
  MAC=`sudo virsh dumpxml fcos-32|grep -i 'mac address'|awk -F'=' '{print $2}'| awk -F"'" '{print $2}'`
  IP=""
  while [[ $IP == "" ]]; do
    IP=`sudo virsh net-dhcp-leases default|grep $MAC|awk '{print $5}'|awk -F'/' '{print $1}'`
    sleep 1
  done
}



kill_fcos-32 () {
  sudo virsh destroy fcos-32
  sudo virsh undefine fcos-32
}
kill_fcos-33 () {
  sudo virsh destroy fcos-33
  sudo virsh undefine fcos-33
}


setup_environment
kill-fcos-32
kill-fcos-33
generate_instances
