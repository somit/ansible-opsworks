require 'json'


# Temporary setup code 
environment = node['ansible']['environment']
layer = node['opsworks']['instance']['layers'].first
playbooks = node['ansible']['playbooks']
folder = node['ansible']['folder']
version = node['ansible']['version']

zippath = '/etc/opsworks-customs'
basepath  = '/etc/opsworks-customs/'+folder


Chef::Log.info("Environment #{environment}")
Chef::Log.info("Layer #{layer}")
Chef::Log.info("Playbooks #{playbooks}")
Chef::Log.info("Folder #{folder}")
Chef::Log.info("zippath #{zippath}")
Chef::Log.info("basepath #{basepath}")
Chef::Log.info("Version #{version}")


directory zippath do
  mode '0755'
  recursive true
  action :create
end


remote_file '/etc/opsworks-customs/ansible.zip' do
  source playbooks
  mode '0755'
  action :create
end


taskname = "extract_ansible_tar_for_"+version

Chef::Log.info("Extracting playbooks")

execute taskname do
  command 'unzip /etc/opsworks-customs/ansible.zip'
  cwd zippath
end

# Temporary setup code ends

Chef::Log.info("Custom ansible data #{node['custom_ansible']}")
Chef::Log.info("Node deploy data #{node['deploy'].to_json}")


extra_vars = {}
app = node['custom_ansible']['app']
extra_vars['opsworks'] = node['opsworks']
extra_vars['ansible']  = node['ansible']
extra_vars['environment_variables'] = node['deploy'][app]['environment_variables'] 
folder = node['ansible']['folder']

zippath = '/etc/opsworks-customs'
basepath  = '/etc/opsworks-customs/'+folder


execute "deploy" do
  command "ansible-playbook -i #{basepath}/inv #{basepath}/deploy.yml --extra-vars '#{extra_vars.to_json}'"
  only_if { ::File.exists?("#{basepath}/deploy.yml")}
  action :run
end

if ::File.exists?("#{basepath}/deploy.yml")
  Chef::Log.info("Log into #{node['opsworks']['instance']['private_ip']} and view /var/log/ansible.log to see the output of your ansible run")
else
  Chef::Log.info("No updates: #{basepath}/deploy.yml not found")
end
