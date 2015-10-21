require File.expand_path('../../../util/smb_file', __FILE__)

Puppet::Type.type(:smb_setting).provide(:ruby) do

  def self.instances
    # this code is here to support purging and the query-all functionality of the
    # 'puppet resource' command, on a per-file basis.  Users
    # can create a type for a specific config file with a provider that uses
    # this as its parent and implements the method
    # 'self.file_path', and that will provide the value for the path to the
    # ini file (rather than needing to specify it on each ini setting
    # declaration).  This allows 'purging' to be used to clear out
    # all settings from a particular ini file except those included in
    # the catalog.

    def self.file_path
      if File.exist?('/etc/samba/smb_path')
         File.open('/etc/samba/smb_path', &:readline).strip
      else
         '/etc/samba/smb.conf'
      end
    end

    def section
      resource[:name].split('/', 2).first
    end
    def setting
      # implement setting as the second part of the namevar
      resource[:name].split('/', 2).last
    end

    if self.respond_to?(:file_path)
      # figure out what to do about the seperator
      resources = []
      if file_path.nil?
        return resources
      end
      smb_file  = Puppet::Util::SmbFile.new(file_path, '=')
      smb_file.section_names.each do |section_name|
        settings = smb_file.get_settings(section_name)
        if settings.length == 0 and section_name != ''
           resources.push(
            new(
              :name   => namevar(section_name, 'emptySection'),
              :value  => 'None',
              :ensure => :present
            )
          )
        else
          settings.each do |setting, value|
            resources.push(
              new(
                :name   => namevar(section_name, setting),
                :value  => value,
                :ensure => :present
              )
            )
          end
        end
      end
      resources
    else
      raise(Puppet::Error, 'Smb_settings only support collecting instances when a file path is hard coded')
    end
  end

  def self.namevar(section_name, setting)
    "#{section_name}/#{setting}"
  end

  def exists?
    setting == 'emptySection' or !smb_file.get_value(section, setting).nil?
  end

  def create
    smb_file.set_value(section, setting, resource[:value])
    smb_file.save
    @smb_file = nil
  end

  def destroy
    smb_file.remove_setting(section, setting)
    smb_file.save
    @smb_file = nil
  end

  def value
    smb_file.get_value(section, setting)
  end

  def value=(value)
    smb_file.set_value(section, setting, resource[:value])
    smb_file.save
  end

  def section
    # this method is here so that it can be overridden by a child provider
    resource[:section]
  end

  def setting
    # this method is here so that it can be overridden by a child provider
    resource[:setting]
  end

  def file_path
    # this method is here to support purging and sub-classing.
    # if a user creates a type and subclasses our provider and provides a
    # 'file_path' method, then they don't have to specify the
    # path as a parameter for every smb_setting declaration.
    # This implementation allows us to support that while still
    # falling back to the parameter value when necessary.
    if self.class.respond_to?(:file_path)
      self.class.file_path
    else
      resource[:path]
    end
  end

  def separator
    if resource.class.validattr?(:key_val_separator)
      resource[:key_val_separator] || '='
    else
      '='
    end
  end

  private
  def smb_file
    @smb_file ||= Puppet::Util::SmbFile.new(file_path, separator)
  end

end
