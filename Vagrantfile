# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.define "samba-bionic" do |box|
    box.vm.box = "ubuntu/bionic64"
    box.vm.box_version = "20180919.0.0"
    box.vm.hostname = "samba-bionic.local"
    box.vm.network "private_network", ip: "192.168.153.100"
    box.vm.synced_folder ".", "/vagrant", type: "virtualbox"
    box.vm.provision "shell" do |s|
      s.path = "vagrant/prepare.sh"
      s.args = ["-n", "samba", "-f", "debian", "-o", "bionic", "-b", "/home/ubuntu"]
    end
    box.vm.provision "shell", inline: "puppet apply --modulepath /home/ubuntu/modules /vagrant/vagrant/simple_share.pp"
    box.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.memory = 1280
    end
  end
end
