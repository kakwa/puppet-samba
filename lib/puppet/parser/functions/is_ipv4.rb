#
# is_ip_address.rb
#

module Puppet::Parser::Functions
  newfunction(:is_ipv4, :type => :rvalue, :doc => <<-EOS
Returns true if the string passed to this function is a valid IPv4 address.
    EOS
  ) do |arguments|

    require 'ipaddr'

    if (arguments.size != 1) then
      raise(Puppet::ParseError, "is_ipv4(): Wrong number of arguments "+
        "given #{arguments.size} for 1")
    end

    begin
      ip = IPAddr.new(arguments[0])
    rescue ArgumentError
      return false
    end

    if ip.ipv4? then
      return true
    else
      return false
    end
  end
end
