Vagrant.configure("2") do |config|
  vm_name = ["server-0", "server-1", "server-2"]
  vm_name.each_with_index do |name, i|
    config.vm.define "#{name}" do |node|
      node.vm.box = "example"
      node.vm.hostname = name
      node.ssh.port = "220#{i}"
      node.vm.network "forwarded_port", id: "ssh", guest: 22, host: "220#{i}", host_ip: "127.0.0.1"
      node.vm.network "private_network", ip: "192.168.121.10#{i}"
      node.vm.provider "virtualbox" do |v|
        v.memory = 512
        v.cpus = 1
      end
    end
  end

  vm_name = ["client-0", "client-1", "client-2"]
  vm_name.each_with_index do |name, i|
    config.vm.define "#{name}" do |node|
      node.vm.box = "example"
      node.vm.hostname = name
      node.ssh.port = "221#{i}"
      node.vm.network "forwarded_port", id: "ssh", guest: 22, host: "221#{i}", host_ip: "127.0.0.1"
      node.vm.network "private_network", ip: "192.168.121.11#{i}"
      node.vm.provider "virtualbox" do |v|
        v.memory = 1536
        v.cpus = 2
      end
    end
  end
end
