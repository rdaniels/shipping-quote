
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
	config.vm.hostname = "shipping"
  config.vm.provider :virtualbox do |vb|
		vb.customize ["modifyvm", :id, "--name", "shipping", "--memory", "512"]
  end
  config.vm.box = "lucid64_final"
  config.vm.network :forwarded_port, guest: 80, host: 4567
  config.vm.network :forwarded_port, guest: 3000, host: 3000
end
