#
# latest version available at: 
# https://github.com/shyiko/docker-vm
#
Vagrant.configure("2") do |config|

  # for box definition go to https://github.com/phusion/open-vagrant-boxes
  config.vm.box = "phusion-open-ubuntu-14.04-amd64"
  config.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-14.04-amd64-vbox.box"

  config.vm.network "private_network", ip: "192.168.42.10"

  # install & start docker daemon
  config.vm.provision "docker", version: "1.6.1"

  # make docker daemon accessible from the host OS (port 2376)   
  config.vm.provision :shell, inline: <<-EOT
    echo 'DOCKER_OPTS="-H unix:// -H tcp://0.0.0.0:2376 ${DOCKER_OPTS}"' >> /etc/default/docker
    service docker restart
  EOT

  if Vagrant::Util::Platform.windows?
    # use MSYS/Cygwin style path(s)
    ["/c/Users/#{ENV['USERNAME']}", "/cygdrive/c/Users/#{ENV['USERNAME']}"].each do |target|
      config.vm.synced_folder "C:/Users/#{ENV['USERNAME']}", target, type: "smb"  
    end
  else
    # mirror /Users/USERNAME
    config.vm.synced_folder "/Users/#{ENV['USER']}", "/Users/#{ENV['USER']}", type: "nfs"
  end
  
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provider "virtualbox" do |v|

    v.customize ["modifyvm", :id, "--nictype1", "virtio" ]
    
    # unless synced_folder's nfs_udp is set to false (which slows things down considerably - up to 50%) 
    # DO NOT change --nictype2 to virtio (otherwise writes may freeze)
    
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]

    v.customize ["modifyvm", :id, "--memory", "2048"]

  end

end
