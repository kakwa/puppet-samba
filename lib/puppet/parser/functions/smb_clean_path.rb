module Puppet::Parser::Functions
  newfunction(:smb_clean_path, :type => :rvalue, :doc => <<-EOS
clean '/' repetitions from a string
ex: smb_clean_path('//my///path') => '/my/path'
    EOS
) do |args|
    raise(Puppet::ParseError, "(smb_clean_path): Wrong number of arguments " +
      "given (#{args.size} for 1)") if args.size < 1

    path = args[0]
    unless path.is_a?(String)
      raise(Puppet::ParseError, 'smb_clean_path(): Requires a ' +
        'string to work with')
    end

    path = path.gsub( /\/\/*/, '/')
    return path
  end
end
