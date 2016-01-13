require 'json'
extra_vars = {}
extra_vars['opsworks'] = node['opsworks']
extra_vars['ansible']  = node['ansible']

Chef::Application.fatal!("'ansible['environment']' must be defined in custom json for the opsworks stack") if node['ansible'].nil? || node['ansible']['environment'].nil? || node['ansible']['environment'].empty?
Chef::Application.fatal!("'ansible['playbooks']' must be defined in custom json for the opsworks stack") if node['ansible'].nil? || node['ansible']['playbooks'].nil? || node['ansible']['playbooks'].empty?
Chef::Application.fatal!("'ansible['folder']' must be defined in custom json for the opsworks stack") if node['ansible'].nil? || node['ansible']['folder'].nil? || node['ansible']['folder'].empty?

apt_package 'ansible' do
  action :install
end


environment = node['ansible']['environment']
layer = node['opsworks']['instance']['layers'].first
playbooks = node['ansible']['playbooks']
folder = node['ansible']['folder']

zippath = '/etc/opsworks-customs'
basepath  = '/etc/opsworks-customs/'+folder

Chef::Log.info("Environment #{environment}")
Chef::Log.info("Layer #{layer}")
Chef::Log.info("Playbooks #{playbooks}")
Chef::Log.info("Folder #{folder}")
Chef::Log.info("zippath #{zippath}")
Chef::Log.info("basepath #{basepath}")



Chef::Log.info("Create zip path")

directory zippath do
  mode '0755'
  recursive true
  action :create
end

Chef::Log.info("Fetching #{playbooks}")

remote_file '/etc/opsworks-customs/ansible.zip' do
  source playbooks
  mode '0755'
  action :create
end

Chef::Log.info("Extracting playbooks")

execute 'extract_some_tar' do
  command 'unzip /etc/opsworks-customs/ansible.zip'
  cwd zippath
end


Chef::Log.info("Setting up role")
# If the role for this layer is defined in custom json then set the role to what's defined
# If not, set the role to the name of the layer
role = node['ansible']['layers'][layer]['role'] rescue nil
if role.nil?
  role = layer
end

Chef::Log.info("Tagging instance")

execute "tag instance" do
  command "aws ec2 create-tags --tags Key=environment,Value=#{environment} Key=role,Value=#{role} --resources `curl http://169.254.169.254/latest/meta-data/instance-id/` --region #{node['opsworks']['instance']['region']}"
  action :run
end

Chef::Log.info("Running setup with .... #{extra_vars.to_json}")

execute "setup" do
  command "ansible-playbook -i #{basepath}/inv #{basepath}/#{node['opsworks']['activity']}.yml --extra-vars '#{extra_vars.to_json}'"
  only_if { ::File.exists?("#{basepath}/#{node['opsworks']['activity']}.yml")}
  action :run
end

if ::File.exists?("#{basepath}/#{node['opsworks']['activity']}.yml")
  Chef::Log.info("Log into #{node['opsworks']['instance']['private_ip']} and view /var/log/ansible.log to see the output of your ansible run")
else
  Chef::Log.info("No updates: #{basepath}/#{node['opsworks']['activity']}.yml not found")
end
