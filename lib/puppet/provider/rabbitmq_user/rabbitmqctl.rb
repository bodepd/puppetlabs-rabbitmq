require 'puppet'
Puppet::Type.type(:rabbitmq_user).provide(:rabbitmqctl) do

  commands :rabbitmqctl => 'rabbitmqctl'
  defaultfor :kernel => :Linux

  def self.instances
    rabbitmqctl('list_users').split(/\n/)[1..-2].collect do |line|
      if line =~ /^(\S+)(\s+\S+|)$/
        new(:name => $1)
      else
        raise Puppet::Error, "Cannot parse invalid user line: #{line}"
      end
    end
  end

  def create
    rabbitmqctl('add_user', resource[:name], resource[:password]) 
    if resource[:admin] == :true
      rabbitmqctl('set_admin', resource[:name])
    end
  end

  def destroy
    rabbitmqctl('delete_user', resource[:name]) 
  end
 
  def exists?
    out = rabbitmqctl('list_users').split(/\n/)[1..-2].detect do |line|
      line.match(/^#{resource[:name]}(\s+\S+|)$/)
    end
  end

  # def password
  # def password=()
  def admin
    match = rabbitmqctl('list_users').split(/\n/)[1..-2].collect do |line|
      line.match(/^#{resource[:name]}\s+(true|false)$/)
    end.compact.first
    if match
      match[1].to_sym
    else
      raise Puppet::Error, "Could not match line '#{resource[:name]} true|false' from list_users"
    end
  end

  def admin=(state)
    if state == :true
      rabbitmqctl('set_admin', resource[:name])
    else
      rabbitmqctl('clear_admin', resource[:name])
    end
  end

end
