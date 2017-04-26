# vagrantfile for functional testing of TransportScheduler application

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  # config.vm.provision :shell, privileged: true, path: "config/vagrant.sh"
  config.vm.network "forwarded_port", guest: 8880, host: 8880

  # VM specific configs
  config.vm.provider "virtualbox" do |v|
    v.gui = false
    v.name = "TransportScheduler"
    v.memory = 2048
    v.cpus = 2
  end

  # Setup synced folder
  config.vm.synced_folder ".", "/home/ubuntu/ts"

  # install dependencies and create a development environment
  config.vm.provision :shell, privileged: true, path: "script/vagrant"
end
