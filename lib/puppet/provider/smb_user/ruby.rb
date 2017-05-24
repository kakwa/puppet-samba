require 'yaml'

Puppet::Type.type(:smb_user).provide(:ruby) do

  commands :sambatool => "/usr/bin/samba-tool"
  commands :sambaclient => "/usr/bin/smbclient"
  commands :sambatooladd => "/usr/local/bin/additional-samba-tool"
  add_entry = false
  modify_password = false
  modify_attr = false
  modify_group = false

  def exists?
     @add_entry = true
     begin
      command = [command(:sambatooladd), '--user', '--list', '--name',resource[:name]]
      output = execute(command)
      Puppet.debug(output)
    rescue Puppet::ExecutionFailure => ex
      raise Puppet::Error, "Failed determine if user '#{resource[:name]}' exists"
    end
    @attr_values = YAML.load(output)
    if not resource[:attributes]
      attrs = []
    else
      attrs = resource[:attributes]
    end
    if @attr_values
      @add_entry = false
      attrs.each do |attr, value|
        if value.is_a? String
          Puppet.debug("#{attr} is a mono-valued attribute")
          if not @attr_values.has_key?(attr) or @attr_values[attr] != value
              Puppet.debug("#{attr} is not set or has a different value")
              @modify_attr = true
          end
        else
          Puppet.debug("#{attr} is a multi-valued attribute")
          if @attr_values[attr].is_a? Array
            Puppet.debug("#{attr} is an array")
            exattrl = @attr_values[attr]
          else
            Puppet.debug("#{attr} is something else")
            exattrl = [@attr_values[attr]]
          end
          if not @attr_values.has_key?(attr) or not value.all? { |i| exattrl.include?(i) }
              Puppet.debug("#{attr} is not set or has a different value")
              @modify_attr = true
          end
        end
      end
    else
      @add_entry = true
      @modify_attr = true
    end
    if (@add_entry == true or resource[:force_password]) and resource[:password].to_s != ''
        begin
          command = [command(:sambaclient), '//localhost/netlogon', resource[:password], "-U#{resource[:name]}", '-c', 'ls']
          output  = execute(command)
          Puppet.debug(output)
        rescue Puppet::ExecutionFailure => ex
          @modify_password = true
        end
    end
    if resource[:groups].is_a? String
      groups = [resource[:groups]]
    else
      groups = resource[:groups]
    end
    groups.each do |group|
      command = [command(:sambatool), 'group', 'listmembers', group, '-d', '1']
      output = execute(command)
      Puppet.debug(output)
      users_list = output.split(/\n/).map(&:downcase)
      if not users_list.include?(resource[:name].downcase)
        @modify_group = true
      end
    end
    return not(@modify_password or @add_entry or @modify_attr or @modify_group)
  end

  def create
    if @add_entry
      begin
        command = [command(:sambatool), 'user', 'create', resource[:name]]
        if resource[:password].to_s != ''
          command.push(resource[:password])
        else
          command.push('--random-password')
        end
        if resource[:given_name].to_s != ''
          command.push('--given-name')
          command.push(resource[:given_name])
        end
        if resource[:use_username_as_cn]
          command.push('--use-username-as-cn')
        end
        command.push('-d')
        command.push('1')
        output = execute(command)
        Puppet.debug(output)
      rescue Puppet::ExecutionFailure => ex
        raise Puppet::Error, "Failed to create user '#{resource[:name]}'"
      end
      begin
        command = [command(:sambatooladd), '--user', '--list', '--name',resource[:name]]
        output = execute(command)
        Puppet.debug(output)
      rescue Puppet::ExecutionFailure => ex
        raise Puppet::Error, "Failed determine if user '#{resource[:name]}' exists"
      end
      @attr_values = YAML.load(output)
    end
    if not resource[:attributes]
      attrs = []
    else
      attrs = resource[:attributes]
    end
    if @modify_attr
      Puppet.notice("Changing attribute(s) of user '#{resource[:name]}'")
      attrs.each do |attr, value|
        if value.is_a? String
          if not @attr_values.has_key?(attr) or @attr_values[attr] != value
              command = [command(:sambatooladd), '--user', '--set', '--name', 
          	resource[:name], '--attribute', attr, '--value', value]
              output = execute(command)
              Puppet.debug(output)
          end
        else
          Puppet.debug("#{attr} is a multi-valued attribute")
          if @attr_values[attr].is_a? Array
            Puppet.debug("#{attr} is an array")
            exattrl = @attr_values[attr]
          else
            exattrl = [@attr_values[attr]]
          end
          if not @attr_values.has_key?(attr) or not value.all? { |i| exattrl.include?(i) }
            value.each do |subvalue|
              if not exattrl.include?(subvalue)
                Puppet.debug("#{exattrl} #{subvalue}")
                command = [command(:sambatooladd), '--user', '--set', '--multi', '--name',
                    resource[:name], '--attribute', attr, '--value', subvalue]
                output = execute(command)
                Puppet.debug(output)
              end
            end
          end
        end
      end
    end
    if @modify_password
      Puppet.notice("Changing password of user '#{resource[:name]}'")
      command = [command(:sambatool), 'user', 'setpassword', resource[:name], '--newpassword', resource[:password], '-d', '1']
      output  = execute(command)
      Puppet.debug(output)
    end
    if @modify_group
      Puppet.notice("Changing group(s) of user '#{resource[:name]}'")
      if resource[:groups].is_a? String
        groups = [resource[:groups]]
      else
        groups = resource[:groups]
      end

      groups.each do |group|
        command = [command(:sambatool), 'group', 'listmembers', group, '-d', '1']
        output = execute(command)
        users_list = output.split(/\n/).map(&:downcase)
        if not users_list.include?(resource[:name].downcase)
          command = [command(:sambatool), 'group', 'addmembers', group, resource[:name], '-d', '1']
          output = execute(command)
          Puppet.debug(output)
        end
      end
    end
  end

  def destroy
    begin
      command = [command(:sambatool), 'user', 'delete', resource[:name], '-d', '1']
      output = execute(command)
      Puppet.debug(output)
    rescue Puppet::ExecutionFailure => ex
      raise Puppet::Error, "Failed to remove user '#{resource[:name]}'"
    end
  end
end
