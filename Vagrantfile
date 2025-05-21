# -*- mode: ruby -*-
# vi: set ft=ruby :

#-----------------------------------------------------------------------------------------------------------------------------------------
# NGINX VM Settings (acts as a load balancer in front of Node.js backend servers)
ngx_vm_name = "loadbalancer-nginx"                      # Unique VM name used for VirtualBox reference
ngx_box_name = "ubuntu/bionic64"                        # Base Ubuntu image to use for the VM
ngx_cpus = 4                                            # Number of CPU cores allocated
ngx_memory = 1024                                       # Amount of RAM in MB
ngx_disk_size = "40GB"                                  # Virtual disk size
ngx_sync_dir_src = "./sync-directories/nginx/"          # Path to local directory containing NGINX config
ngx_sync_dir_dest = "/etc/nginx/conf.d"                 # Path in the VM where config will be synced
ngx_provisioning_script = "./scripts/provision_ngx.sh"  # Shell script to install/configure NGINX
ngx_hostname = "loadbalancer"                           # Hostname set inside the VM (used in /etc/hosts)
ngx_private_ip = "192.168.56.10"                        # Internal private network IP address
ngx_port = 80                                           # HTTP port (typically forwarded externally if needed)

#-----------------------------------------------------------------------------------------------------------------------------------------
# Node.js VM Settings (represent multiple application backend servers)
node_box_name = "ubuntu/focal64"                        # Base image for all Node.js VMs
node_cpus = 4                                           # CPUs per VM (currently commented in provider config)
node_memory = 512                                       # Memory per VM (also commented out below)
node_disk_size = "40GB"                                 # Disk size per VM
node_sync_dir_src = "./sync-directories/app/"           # Path to local Node.js application directory
node_sync_dir_dest = "/node-app"                        # Destination folder in the VM for synced app code
node_provisioning_script = "./scripts/provision_app.sh" # Script to install Node, dependencies, etc.
# Define a list of Node.js VMs with unique names, IPs, and ports
node_vms = [
  { 
    name: "nodejs-1",                                   # VM name in VirtualBox
    hostname: "nodejs1",                                # Hostname inside VM
    ip: "192.168.56.13",                                # Private IP for internal communication
    port: "3000"                                        # Node.js app listening port
  },
  {
    name: "nodejs-2",
    hostname: "nodejs2",
    ip: "192.168.56.14",
    port: "3000"
  }
]
#-----------------------------------------------------------------------------------------------------------------------------------------
# Redis VM Settings (for caching layer, used by backend)
rds_vm_name = "rds-server"                              # VM name for Redis instance
rds_box_name = "ubuntu/bionic64"                        # Base image for Redis VM
rds_cpus = 4
rds_memory = 1024
rds_disk_size = "40GB"
rds_provisioning_script = "./scripts/provision_rds.sh"  # Shell script to install/configure Redis
rds_hostname = "redis"                                  # Hostname set in VM
rds_private_ip = "192.168.56.11"                        # Internal IP for Redis server

#-----------------------------------------------------------------------------------------------------------------------------------------
# MySQL/DB VM Settings (for persistent storage)
db_vm_name = "db-server"
db_box_name = "ubuntu/jammy64"                          # More recent Ubuntu version
db_cpus = 4
db_memory = 1024
db_disk_size = "40GB"
db_provisioning_script = "./scripts/provision_db.sh"    # Shell script to install MySQL
db_hostname = "mysql"
db_private_ip = "192.168.56.12"
#-----------------------------------------------------------------------------------------------------------------------------------------

Vagrant.configure("2") do |config|

  # Redis Server Vm Settings
  config.vm.define rds_vm_name do |rds|
    rds.vm.provider "virtualbox" do |vb|
      vb.name = rds_vm_name
      # Optional: Uncomment to explicitly set CPU and memory
      # vb.cpus = rds_cpus
      # vb.memory = rds_memory
    end
    rds.vm.box = rds_box_name
    rds.vm.disk :disk, size: rds_disk_size, primary: true
    rds.vm.hostname = rds_hostname
    rds.vm.network "private_network", ip: rds_private_ip
    rds.vm.provision "shell", path: rds_provisioning_script,
      env: {
        "REMOTE_HOSTS" => node_vms.map { |n| n[:ip] }.join(',')
      }
  end

  # DB Server Vm Settings
  config.vm.define db_vm_name do |db|
    db.vm.provider "virtualbox" do |vb|
      vb.name = db_vm_name
      # Optional: Uncomment to explicitly set CPU and memory
      # vb.cpus = db_cpus
      # vb.memory = db_memory
    end
    db.vm.box = db_box_name
    db.vm.disk :disk, size: db_disk_size, primary: true
    db.vm.hostname = db_hostname
    db.vm.network "private_network", ip: db_private_ip
    db.vm.provision "shell", path: db_provisioning_script,
      env: { 
        "REMOTE_HOSTS" => node_vms.map { |n| n[:ip] }.join(',') 
      }
  end

  # Backend Vm Settings
  node_vms.each do |vm_config|
    config.vm.define vm_config[:name] do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = vm_config[:name]
      # Optional: Uncomment to explicitly set CPU and memory
        # vb.cpus = node_cpus
        # vb.memory = node_memory
      end
      node.vm.box = node_box_name
      node.vm.hostname = vm_config[:hostname]
      node.vm.network "private_network", ip: vm_config[:ip]
      node.vm.disk :disk, size: node_disk_size, primary: true
      node.vm.synced_folder node_sync_dir_src, node_sync_dir_dest
      node.vm.provision "shell", path: node_provisioning_script,
        env: {
          "NODE_HOST" => vm_config[:ip],
          "NODE_PORT" => vm_config[:port].to_s,
          "REMOTE_HOSTS" => "192.168.56.10"
        }
      # Add Redis and DB server entries to /etc/hosts for name resolution
      node.vm.provision "shell", run: "once", inline: <<-"SHELL_EOF"
      echo "Setting up /etc/hosts entries"
        echo '#{db_private_ip} #{db_hostname}' >> /etc/hosts
        echo '#{rds_private_ip} #{rds_hostname}' >> /etc/hosts
      SHELL_EOF
    end
  end

  # NGINX Web Server Vm Settings
  config.vm.define ngx_vm_name do |ngx|
    ngx.vm.provider "virtualbox" do |vb|
      vb.name = ngx_vm_name
      # Optional: Uncomment to explicitly set CPU and memory
      # vb.cpus = ngx_cpus
      # vb.memory = ngx_memory
    end
    ngx.vm.box = ngx_box_name
    ngx.vm.disk :disk, size: ngx_disk_size, primary: true
    ngx.vm.hostname = ngx_hostname
    ngx.vm.network "private_network", ip: ngx_private_ip
    ngx.vm.synced_folder ngx_sync_dir_src, ngx_sync_dir_dest
    # Add Node.js app server hostnames to /etc/hosts for routing
    ngx.vm.provision "shell", run: "once", inline: <<-"SHELL_EOF"
      echo "Setting up /etc/hosts entries"
      #{node_vms.map { |vm| "echo '#{vm[:ip]} #{vm[:hostname]}' >> /etc/hosts" }.join("\n")}
    SHELL_EOF
    # Run shell script to install NGINX and any required load balancer configuration
    ngx.vm.provision "shell", path: ngx_provisioning_script
  end
end
