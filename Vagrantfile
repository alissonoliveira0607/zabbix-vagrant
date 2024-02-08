Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"
    config.vm.hostname = "zabbix"
  
    config.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = 2
      vb.name = "ZABBIX"
    end
  
    config.vm.network "public_network", bridge: "Ethernet"
    config.vm.provision "shell",  path: "provision.sh"
  end
  

  
