require 'yaml'
require_relative 'build/vagrant'

# Just require ansible on the running host
if !which('ansible-playbook')
	print 'Sorry, ansible is required to run Oomphrock. You can probably install it very easily with "brew install ansible"'

	exit 1
end

dir = File.dirname(File.expand_path(__FILE__))
vars = YAML.load_file("#{dir}/provisioning/vars.yml")

# Require certain plugins
plugins = ['vagrant-hostsupdater', 'vagrant-cachier']
plugins.each do |plugin|
  unless Vagrant.has_plugin?(plugin)
    puts "Attempting to install " + plugin
    # Attempt to install required plugins ourselves
    system('vagrant plugin install ' + plugin) || exit
    # Relaunch Vagrant so the plugin is detected. Exit with the same status code
    exit system('vagrant', *ARGV)
  end
end

#If your Vagrant version is lower than 1.5, you can still use this provisioning
#by commenting or removing the line below and providing the config.vm.box_url parameter,
#if it's not already defined in this Vagrantfile. Keep in mind that you won't be able
#to use the Vagrant Cloud and other newer Vagrant features.
Vagrant.require_version ">= 1.5"

dumpfile = ''

# Ensure all paths are relative to the Vagrantfile
Dir.chdir(File.dirname(__FILE__))

# Download a DB dump from a source if given
if vars.key?('db_dump_source') && !vars['db_dump_source'].empty?
  dumpfile = File.basename(vars['db_dump_source'])

  unless File.exist? dumpfile
    system("scp #{vars['db_dump_source']} #{dumpfile}")
  end
end

Vagrant.configure("2") do |config|
	box_name = "#{vars['project_name']} Development"
	hostname = vars['hostname']
	vm = vars['vagrant_local']['vm']

	if Vagrant.has_plugin?("vagrant-cachier")
		config.cache.scope = :box
		config.cache.auto_detect = false
		config.cache.enable :apt
	end

  config.vm.define hostname do |host|
    host.vm.provider :virtualbox do |v|
      v.name = hostname
      v.customize [
        "modifyvm", :id,
        "--name", hostname,
        "--memory", vm['memory'],
        "--natdnshostresolver1", "on",
        "--cpus", vm['cpus'],
      ]
    end

    host.vm.box = "ubuntu/trusty64"
    host.vm.network :private_network, ip: vm['ip']
    host.vm.hostname = hostname
    host.ssh.forward_agent = true

    # Provision with ansible
    host.vm.provision "ansible" do |ansible|
      ansible.playbook = "provisioning/playbook.yml"
      ansible.limit = hostname
      ansible.groups = {
        "vagrant" => [hostname]
      }

      if !dumpfile.empty?
        ansible.extra_vars = { db_dump: dumpfile }
      end

      if vars.key?('provision_verbose') && vars['provision_verbose'] > 0
        ansible.verbose = vars['provision_verbose']
      end
    end

    host.vm.synced_folder "./", "/vagrant", owner: "vagrant", group: "vagrant"

    # Ensure the webserver owns the web root but can be written to by vagrant
    host.vm.synced_folder "./web", "/vagrant/web", owner: "www-data", group: "vagrant", mount_options: ["dmode=775,fmode=664"]

    # Sync composer file to leverage local composer cache for vagrant user
    host.vm.synced_folder "#{ENV['HOME']}/.composer", "/home/vagrant/.composer", owner: "vagrant", group: "vagrant"
  end
end
