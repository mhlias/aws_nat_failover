#!/usr/bin/env ruby

require 'aws-sdk'
require 'facter'

region  = ARGV[0]
tag_key = ARGV[1]
tag_val = ARGV[2]

$quit = false
pidfile = '/var/run/aws_nat_failover.pid'

def start(region, tag_key, tag_val)

  destination_cidr_block = '0.0.0.0/0'

  # Health Check variables
  num_pings    = 3
  ping_timeout = 1
  interval     = 2

  Aws.config.update({
    region: region,
    credentials: Aws::InstanceProfileCredentials.new,
  })

  my_az = Facter.value('ec2_placement_availability_zone')
  my_id = Facter.value('ec2_instance_id')

  azs = { "a"=>"b", "b"=>"c", "c"=>"a" }

  az_letter = my_az[my_az.length-1]

  client = Aws::EC2::Client.new

  ec2 = Aws::EC2::Resource.new(client)

  my_instance = ec2.instance(my_id)
  vpc_id = my_instance.vpc_id

  enis = ec2.network_interfaces({
    filters: [
      name: "vpc-id",
      values: [vpc_id],
      name: "tag-key",
      values: [tag_key],
      name: "tag-value",
      values: [tag_val],
    ]
    })

  monit_ip = nil
  my_eni_id = nil
  monit_eni_id = nil
  my_rt_id = nil
  monit_rt_id = nil

  enis.each do |eni|
    if eni.vpc_id == vpc_id
      if eni.availability_zone == "#{region}#{azs[az_letter]}"
        monit_ip = eni.private_ip_address
        monit_eni_id = eni.network_interface_id
      elsif eni.availability_zone == my_az
        my_eni_id = eni.network_interface_id
     end
    end
  end

  rts = ec2.route_tables({
    filters: [
      name: "vpc-id",
      values: [vpc_id],
      name: "tag-key",
      values: ["eni_id"],
      name: "tag-value",
      values: [monit_eni_id],
    ]
    })

  rts.each do |rt|
    if rt.vpc_id == vpc_id
      monit_rt_id = rt.id
    end
  end

  rts = ec2.route_tables({
    filters: [
      name: "vpc-id",
      values: [vpc_id],
      name: "tag-key",
      values: ["eni_id"],
      name: "tag-value",
      values: [my_eni_id],
    ]
    })

  rts.each do |rt|
    if rt.vpc_id == vpc_id
      my_rt_id = rt.id
    end
  end

  route = Aws::EC2::Route.new(my_rt_id, destination_cidr_block, options = {})
  route.replace({
    network_interface_id: my_eni_id,
  })


  while (!$quit) do
   # Check health of other BASTION instance
     
    result = `ping -q -c #{num_pings} #{monit_ip}`
    if ($?.exitstatus > 0)
     # Set HEALTHY variables to unhealthy (0)
     route_healthy = 0
     nat_healthy   = 0
     while nat_healthy == 0 do
       # NAT instance is unhealthy, loop while the auto-scaling group is taking action to recover
       if route_healthy == 0
        route = Aws::EC2::Route.new(monit_rt_id, destination_cidr_block, options = {})
        route.replace({
          network_interface_id: my_eni_id,
        })
        route_healthy = 1
       end
       result = `ping -q -c #{num_pings} #{monit_ip}`
       if ($?.exitstatus == 0)
        nat_healthy = 1
       end
       sleep interval
     end
   else
    sleep interval
   end
  end

end


def daemonize
  exit if fork
  Process.setsid
  exit if fork
  Dir.chdir "/"
end

def write_pid(pidfile)
  begin
    File.open(pidfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY){|f| f.write("#{Process.pid}") }
    at_exit { File.delete(pidfile) if File.exists?(pidfile) }
  rescue Errno::EEXIST
    check_pid
    retry
  end
end

def check_pid(pidfile)
  case pid_status(pidfile)
  when :running, :not_owned
    puts "Service is already running. Check #{pidfile}"
    exit(1)
  when :dead
    File.delete(pidfile)
  end
end

def pid_status(pidfile)
  return :exited unless File.exists?(pidfile)
  pid = ::File.read(pidfile).to_i
  return :dead if pid == 0
  Process.kill(0, pid)
  :running
rescue Errno::ESRCH
  :dead
rescue Errno::EPERM
  :not_owned
end


def trap_signals
  trap(:QUIT) do
    $quit = true
    exit(0)
  end
end



check_pid(pidfile)
write_pid(pidfile)
trap_signals
start(region, tag_key, tag_val)
