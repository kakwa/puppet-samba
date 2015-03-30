require 'yaml'

Puppet::Type.type(:smb_user).provide(:ruby) do

  commands :sambatool => "/usr/bin/samba-tool"
  commands :sambatooladd => "/usr/local/bin/additional-samba-tool"
  add_entry = false

  def exists?
     ret = true
     begin
      command = [command(:sambatooladd), '--user', '--list', '--name',resource[:name]]
      output = execute(command)
      Puppet.debug(output)
    rescue Puppet::ExecutionFailure => ex
      raise Puppet::Error, "Failed determine if user '#{resource[:name]}' exists"
    end
    @attr_values = YAML.load(output)
    if @attr_values
      @add_entry = false
      resource[:attributes].each do |attr, value|
        if value.is_a? String
          Puppet.debug("#{attr} is a mono-valued attribute")
          if not @attr_values.has_key?(attr) or @attr_values[attr] != value
              Puppet.debug("#{attr} is not set or has a different value")
              ret = false
          end
        else
          Puppet.debug("#{attr} is a multi-valued attribute")
          if @attr_values[attr].is_a? Array
            Puppet.debug("#{attr} is an array")
            exattrl = attr
          else
            Puppet.debug("#{attr} is something else")
            exattrl = [attr]
          end
          if not @attr_values.has_key?(attr) or exattrl.all? { |i| exattrl.include?(i) }
              Puppet.debug("#{attr} is not set or has a different value")
              ret = false
          end
        end
      end
      ret
    else
      @add_entry = true
      false
    end
  end

  def create
    if @add_entry
      begin
        #command = [command(:sambatool), 'user', 'create', resource[:name], resource[:password]]
        command = [command(:sambatool), 'user', 'create', resource[:name]]
        output = execute(command)
        Puppet.debug(output)
      rescue Puppet::ExecutionFailure => ex
        raise Puppet::Error, "Failed to create user '#{resource[:name]}'"
      end
    end
    resource[:attributes].each do |attr, value|
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
          exattrl = attr
        else
          exattrl = [attr]
        end
        if not @attr_values.has_key?(attr) or exattrl.all? { |i| exattrl.include?(i) }
          value.each do |subvalue|
            command = [command(:sambatooladd), '--user', '--set', '--multi', '--name',
		resource[:name], '--attribute', attr, '--value', subvalue]
            output = execute(command)
            Puppet.debug(output)
          end
        end
      end
    end
  end

  def destroy
    begin
      command = [command(:sambatool), 'user', 'delete', resource[:name]]
      output = execute(command)
      Puppet.debug(output)
    rescue Puppet::ExecutionFailure => ex
      raise Puppet::Error, "Failed to remove user '#{resource[:name]}'"
    end
  end

  def attributes
  end

  def attributes=(value)
      resource[:attributes].keys do |attr|
        if resource[:attributes][attr].is_array?
          Puppet.debug("#{attr} is a multi-valued attribute")
        else
          Puppet.debug("#{attr} is a mono-valued attribute")
        end
      end
	
  end

end
