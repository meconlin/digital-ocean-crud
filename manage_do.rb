require 'droplet_kit'
require 'table_print'
require 'optparse'
require 'colorize'
require 'yaml'

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
    else
      @key = key
    end

    if @key.nil?
      puts "not api key found, is your config.yml file in place?".red
      exit
    end
    tp.set DropletKit::Droplet, :id, :name, :status, :memory, :created_at
  end

  def delete id
    delete = client.droplets.delete(id: id)
    if delete == true
      puts "Success delete of id : #{id} : #{delete}".green
    else
      puts "Failure to delete : #{id} : #{delete}".red
    end
  end

  def add name
    droplet = DropletKit::Droplet.new(name: name, region: 'nyc2', image: 'ubuntu-14-04-x64', size: '512mb')
    created = client.droplets.create(droplet)
    if created.class == DropletKit::Droplet
      puts "Success ADD : droplet created".green
      tp created
    else
      puts "Failure ADD : not created : #{created}".red
    end
  end

  def list
    puts ""
    answer = client.droplets.all
    tp client.droplets.all
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
  opt.separator  ""
  opt.separator  "Options"

  opt.on("-i","--instance=[INSTNACE_ID]", "which instance to remove (id not name)") do |instance_id|
    options[:instance_id] = instance_id
  end

  options[:name] = nil
  opt.on("-n","--name=[NAME]", "name for new instance") do |name|
    options[:name] = name
  end

  opt.on("-h","--help","help") do
    puts opt_parser
  end
end

opt_parser.parse!

# init with key
mdo = ManageDo.new

case ARGV[0]
when "list"
  mdo.list
when "add"
  puts "ADD called with : #{options[:name]}"
  if !options[:name]
    puts "WARNING : --name is required to add an instance".yellow
    puts opt_parser
    exit
  else
    mdo.add options[:name]
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
