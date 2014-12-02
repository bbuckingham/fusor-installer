if app_value(:provisioning_wizard) != 'none'
  require File.join(KafoConfigure.root_dir, 'hooks', 'lib', 'base_wizard.rb')
  require File.join(KafoConfigure.root_dir, 'hooks', 'lib', 'provisioning_wizard.rb')
  provisioning_wizard = ProvisioningWizard.new(kafo)
  provisioning_wizard.start

  if provisioning_wizard.configure_networking || provisioning_wizard.configure_firewall
    command = PuppetCommand.new(%Q(class {"foreman::plugin::fusor_network":
      interface            => "#{provisioning_wizard.interface}",
      ip                   => "#{provisioning_wizard.ip}",
      netmask              => "#{provisioning_wizard.netmask}",
      gateway              => "#{provisioning_wizard.own_gateway}",
      dns                  => "#{provisioning_wizard.dns}",
      configure_networking => #{provisioning_wizard.configure_networking},
      configure_firewall   => #{provisioning_wizard.configure_firewall},
    }))
    command.append '2>&1'
    command = command.command

    say 'Starting networking setup'
    logger.debug "running command to set networking"
    logger.debug `#{command}`

    if $?.success?
      say 'Networking setup has finished'
    else
      say "<%= color('Networking setup failed', :bad) %>"
      kafo.class.exit(101)
    end
  end

  param('foreman_proxy', 'tftp_servername').value = provisioning_wizard.ip
  param('foreman_proxy', 'dhcp_interface').value = provisioning_wizard.interface
  param('foreman_proxy', 'dhcp_gateway').value = provisioning_wizard.gateway
  param('foreman_proxy', 'dhcp_range').value = "#{provisioning_wizard.from} #{provisioning_wizard.to}"
  param('foreman_proxy', 'dhcp_nameservers').value = provisioning_wizard.ip
  param('foreman_proxy', 'dns_interface').value = provisioning_wizard.interface
  param('foreman_proxy', 'dns_zone').value = provisioning_wizard.domain
  param('foreman_proxy', 'dns_reverse').value = provisioning_wizard.ip.split('.')[0..2].reverse.join('.') + '.in-addr.arpa'
  param('foreman_proxy', 'dns_forwarders').value = provisioning_wizard.dns
  param('foreman_proxy', 'foreman_base_url').value = provisioning_wizard.base_url

  param('foreman_plugin_fusor', 'configure_networking').value = provisioning_wizard.configure_networking
  param('foreman_plugin_fusor', 'configure_firewall').value = provisioning_wizard.configure_firewall
  param('foreman_plugin_fusor', 'interface').value = provisioning_wizard.interface
  param('foreman_plugin_fusor', 'ip').value = provisioning_wizard.ip
  param('foreman_plugin_fusor', 'netmask').value = provisioning_wizard.netmask
  param('foreman_plugin_fusor', 'own_gateway').value = provisioning_wizard.own_gateway
  param('foreman_plugin_fusor', 'gateway').value = provisioning_wizard.gateway
  param('foreman_plugin_fusor', 'dns').value = provisioning_wizard.dns
  param('foreman_plugin_fusor', 'network').value = provisioning_wizard.network
  param('foreman_plugin_fusor', 'from').value = provisioning_wizard.from
  param('foreman_plugin_fusor', 'to').value = provisioning_wizard.to
  param('foreman_plugin_fusor', 'domain').value = provisioning_wizard.domain
  param('foreman_plugin_fusor', 'base_url').value = provisioning_wizard.base_url
  param('foreman_plugin_fusor', 'ntp_host').value = provisioning_wizard.ntp_host
  param('foreman_plugin_fusor', 'timezone').value = provisioning_wizard.timezone

  # some enforced values for foreman-installer
  param('foreman_proxy', 'tftp').value = true
  param('foreman_proxy', 'dhcp').value = true
  param('foreman_proxy', 'dns').value = true
  param('foreman_proxy', 'repo').value = 'nightly'
  param('foreman', 'repo').value = 'nightly'

  param('puppet', 'server').value = true
end
