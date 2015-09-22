require 'droplet_kit'
require 'table_print'
require 'optparse'
require 'colorize'
require 'yaml'
require 'pry'

class ManageDo

  def client
    if !@client
      @client = DropletKit::Client.new(access_token: @key)
    end
    return @client
  end

  def initialize key=nil
    if !key
      config = YAML.load_file('config.yml')
      @key = config["key"]
      @scp_key = config["scp_key_location"]
      @install_file = config["install_file"] || "deploy/install.sh"  # note relative path here
    else
      @key = key
    end

    if @key.nil?
      puts "not api key found, is your config.yml file in place?".red
      exit
    end
  end

  def bounce id, service
    ip = get_ip id
    bounce_command = "ssh -i #{@scp_key} root@#{ip} 'service captcha-vin-decode restart'"
    puts "bouncing with : #{bounce_command}"
    system( bounce_command )
    puts "SUCCESS : bounce done : #{id}".green
  end

  def install id
    ip = get_ip id
    install_command = "scp -i #{@scp_key} #{@install_file} root@#{ip}:install.sh"
    puts "installing with : #{install_command}".yellow
    system( install_command )
    run_command = "ssh -i #{@scp_key} root@#{ip} 'chmod 755 install.sh && ./install.sh'"
    puts "running setup with : #{run_command}".yellow
    system( run_command )
    puts "SUCCESS : install done : #{id}".green
  end

  def delete id
    delete = client.droplets.delete(id: id)
    if delete == true
      puts "Success delete of id : #{id} : #{delete}".green
    else
      puts "Failure to delete : #{id} : #{delete}".red
    end
  end

  def list_keys
    keys = client.ssh_keys.all
    tp keys.entries, :id, :name
  end

  def list_images
    images = client.images.all
    tp images.entries, :id, :name
  end

  # assumes you want to use first available key
  def get_key
    key = client.ssh_keys.all.entries.first
    puts "using key : #{key.id} : #{key.name}"
    return key
  end

  def get_ip id
    droplet = client.droplets.find(id: id)
    return droplet.networks.v4[0].ip_address
  end

  def add name, image='ubuntu-14-04-x64'

    params = {
      name: name,
      region: 'nyc2',
      image: image,
      size: '512mb',
      ssh_keys: [get_key.id]
    }

    puts "adding box with params : #{params}"

    droplet = DropletKit::Droplet.new( params )
    created = client.droplets.create(droplet)
    if created.class == DropletKit::Droplet
      puts "Success ADD : droplet created".green
      tp created, :id, :name, :status, :memory, :created_at
    else
      puts "Failure ADD : not created : #{created}".red
    end
  end

  def list
    puts ""
    l =  lambda do |entry|
      if entry.status == "active"
        return entry.networks.v4[0].ip_address
      else
        return "unknown"
      end
    end

    answer = client.droplets.all
    tp answer.entries, :id, :name, :status, :memory, :created_at, :ip => { :display_method => l }
    puts ""
  end

end


options = {}

opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: manage_do COMMAND [OPTIONS]"
  opt.separator  ""
  opt.separator  "Commands"
  opt.separator  "     list: list all instances"
  opt.separator  "     add: add an instance - NAME is required"
  opt.separator  "     delete: delete an instance - INSTANCE_ID is required"
  opt.separator  "     install: run install on an instance - INSTANCE_ID is required"
  opt.separator  "     bounce: restart a service on a box -INSTANCE_ID is required -SERVICE is required"
  opt.separator  ""
  opt.separator  "Options"

  opt.on("-i","--instance=[INSTNACE_ID]", "which instance to remove (id not name)") do |instance_id|
    options[:instance_id] = instance_id
  end

  opt.on("-s","--service=[SERVICE]", "which service to restart") do |service|
    options[:service] = service
  end

  options[:name] = nil
  opt.on("-n","--name=[NAME]", "name for new instance") do |name|
    options[:name] = name
  end

  options[:image] = nil
  opt.on("-m","--image=[IMAGE]", "image (id) for new instance (defaults to ubuntu-14)") do |image|
    options[:image] = image
  end

  opt.on("-h","--help","help") do
    puts opt_parser
  end
end

opt_parser.parse!

# init with key
mdo = ManageDo.new

case ARGV[0]
when "install"
  if !options[:instance_id]
    puts "WARNING : --instance_id is required to install an instance".yellow
    puts opt_parser
    exit
  else
    mdo.install options[:instance_id]
  end
when "keys"
  mdo.list_keys
when "images"
  mdo.list_images
when "bounce"
  if !options[:instance_id] or !options[:service]
    puts "WARNING : --instance_id and --service are required to bounce an instance".yellow
    puts opt_parser
    exit
  else
    mdo.bounce options[:instance_id], options[:service]
  end
when "list"
  mdo.list
when "add"
  puts "ADD called with : #{options[:name]} : #{options[:image]}"
  if !options[:name]
    puts "WARNING : --name is required to add an instance".yellow
    puts opt_parser
    exit
  else
    if options[:image]
      mdo.add options[:name], options[:image]
    else
      mdo.add options[:name]
    end
    mdo.list
  end
when "delete"
  puts "DELETE called with : #{options[:instance_id]}"
  if !options[:instance_id]
    puts "WARNING : --instance_id is required to remove an instance".yellow
    puts opt_parser
    exit
  else
    mdo.delete options[:instance_id]
    mdo.list
  end
else
  puts opt_parser
end
