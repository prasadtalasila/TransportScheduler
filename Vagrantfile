# vagrantfile for functional testing of TransportScheduler application

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"
  # config.vm.provision :shell, privileged: true, path: "config/vagrant.sh"
  config.vm.network :forwarded_port, guest: 22, host: 12914, id: 'ssh'
  config.vm.network "forwarded_port", guest: 8880, host: 8880
end
