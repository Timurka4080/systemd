# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"

  config.vm.provider "virtualbox" do |v|
    v.memory = 512
    v.cpus = 1
  end

  config.vm.define "systemd" do |systemd|
    systemd.vm.network "private_network", ip: "192.168.50.10", virtualbox__intnet: "net1"
    systemd.vm.hostname = "systemd"
    systemd.vm.provision "shell", path: "systemd_script.sh"
  end
end
