require 'json'

extra_vars = {}
extra_vars['opsworks'] = node['opsworks']
extra_vars['ansible']  = node['ansible']
folder = node['ansible']['folder']
basepath  = '/etc/opsworks-customs/'+folder

execute "undeploy" do
  command "ansible-playbook -i #{basepath}/inv #{basepath}/#{node['opsworks']['activity']}.yml --extra-vars '#{extra_vars.to_json}'"
  only_if { ::File.exists?("#{basepath}/#{node['opsworks']['activity']}.yml")}
  action :run
end

if ::File.exists?("#{basepath}/#{node['opsworks']['activity']}.yml")
  Chef::Log.info("Log into #{node['opsworks']['instance']['private_ip']} and view /var/log/ansible.log to see the output of your ansible run")
else
  Chef::Log.info("No updates: #{basepath}/#{node['opsworks']['activity']}.yml not found")
end
