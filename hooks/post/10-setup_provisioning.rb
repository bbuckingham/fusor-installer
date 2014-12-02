if app_value(:provisioning_wizard) != 'none' && [0,2].include?(kafo.exit_code)
  puts "Starting configuration..."

  # we must enforce at least one puppet run
  logger.debug 'Running puppet agent to seed foreman data'
  `service puppet stop`
  `puppet agent -t`
  `service puppet start`
  logger.debug 'Puppet agent run finished'

  logger.debug 'Installing puppet modules'
  `/usr/share/foreman-installer/hooks/lib/install_modules.sh`
  `foreman-rake puppet:import:puppet_classes[batch]`
  # run import
  logger.debug 'Puppet modules installed'

  `foreman-rake db:migrate`
  `foreman-rake db:seed`
else
  say "Not running provisioning configuration since installation encountered errors, exit code was <%= color('#{kafo.exit_code}', :bad) %>"
  false
end
