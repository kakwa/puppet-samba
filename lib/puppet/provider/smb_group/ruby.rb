require 'yaml'

Puppet::Type.type(:smb_group).provide(:ruby) do

  commands :sambatool => "/usr/bin/samba-tool"
  commands :sambaclient => "/usr/bin/smbclient"
  commands :sambatooladd => "/usr/local/bin/additional-samba-tool"
  add_entry = false
  modify_attr = false
  modify_group = false

  def exists?
     @add_entry = true
     begin
      command = [command(:sambatooladd), '--group', '--list', '--name',resource[:name]]
      output = execute(command)
      Puppet.debug(output)
    rescue Puppet::ExecutionFailure => ex
      raise Puppet::Error, "Failed determine if group '#{resource[:name]}' exists"
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
    if resource[:groups].is_a? String
      groups = [resource[:groups]]
    else
      groups = resource[:groups]
    end
    groups.each do |group|
      command = [command(:sambatool), 'group', 'listmembers', group, '-d', '1']
      output = execute(command)
      Puppet.debug(output)
      groups_list = output.split(/\n/).map(&:downcase)
      if not groups_list.include?(resource[:name].downcase)
        @modify_group = true
      end
    end
    return not(@add_entry or @modify_attr or @modify_group)
  end

  def create
    if @add_entry
      begin
        command = [command(:sambatool), 'group', 'add', resource[:name], '-d', '1', 
	  '--group-scope', resource[:scope], '--group-type', resource[:type]]
        output = execute(command)
        Puppet.debug(output)
      rescue Puppet::ExecutionFailure => ex
        raise Puppet::Error, "Failed to create group '#{resource[:name]}'"
      end
      begin
        command = [command(:sambatooladd), '--group', '--list', '--name',resource[:name]]
        output = execute(command)
        Puppet.debug(output)
      rescue Puppet::ExecutionFailure => ex
        raise Puppet::Error, "Failed determine if group '#{resource[:name]}' exists"
      end
      @attr_values = YAML.load(output)
    end
    if not resource[:attributes]
      attrs = []
    else
      attrs = resource[:attributes]
    end
    if @modify_attr
      Puppet.notice("Changing attribute(s) of group '#{resource[:name]}'")
      attrs.each do |attr, value|
        if value.is_a? String
          if not @attr_values.has_key?(attr) or @attr_values[attr] != value
              command = [command(:sambatooladd), '--group', '--set', '--name', 
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
                command = [command(:sambatooladd), '--group', '--set', '--multi', '--name',
                    resource[:name], '--attribute', attr, '--value', subvalue]
                output = execute(command)
                Puppet.debug(output)
              end
            end
          end
        end
      end
    end
    if @modify_group
      Puppet.notice("Changing group(s) of group '#{resource[:name]}'")
      if resource[:groups].is_a? String
        groups = [resource[:groups]]
      else
        groups = resource[:groups]
      end

      groups.each do |group|
        command = [command(:sambatool), 'group', 'listmembers', group, '-d', '1']
        output = execute(command)
        groups_list = output.split(/\n/).map(&:downcase)
        if not groups_list.include?(resource[:name].downcase)
          command = [command(:sambatool), 'group', 'addmembers', group, resource[:name], '-d', '1']
          output = execute(command)
          Puppet.debug(output)
        end
      end
    end
  end

  def destroy
    begin
      command = [command(:sambatool), 'group', 'delete', resource[:name], '-d', '1']
      output = execute(command)
      Puppet.debug(output)
    rescue Puppet::ExecutionFailure => ex
      raise Puppet::Error, "Failed to remove group '#{resource[:name]}'"
    end
  end
end
