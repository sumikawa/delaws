#!/usr/bin/env ruby
require 'aws-sdk-core'
require 'pp'
require 'pry'
require 'inifile'
require 'optparse'
require_relative 'findid'

ini = IniFile.load(File.expand_path("~/.aws/config"))

region = nil
OptionParser.new do |opt|
  opt.on('--region REGION') {|v| region=v }
  opt.parse!(ARGV)
end

Aws.config = {
  access_key_id: ini['default']['aws_access_key_id'],
  secret_access_key: ini['default']['aws_secret_access_key'],
  region: region.nil? ? ini['default']['region'] : region,
}

@idx = {}

ec2 = Aws::EC2.new
['vpc', 'subnet', 'volume'].each do |r|
  eval("ec2.describe_#{r}s.first.#{r}s").each do |h|
    findid(h, "_id", "#{r}_id")
  end
end

reservations = ec2.describe_instances.reservations
if reservations
  reservations.each do |reservation|
    instance = reservation.instances.first
    findid(instance, "(security_groups|_id)", "instance_id")
  end
end

elb = Aws::ElasticLoadBalancing.new
rs = elb.describe_load_balancers.load_balancer_descriptions
if rs
  rs.each do |r|
    findid(r, "(security_groups|subnets|vpc_id)", "load_balancer_name")
  end
end

rds = Aws::RDS.new
rs = rds.describe_db_instances.db_instances
if rs
  rs.each do |r|
    r.each do |k, v|
      if k =~ /_id$/ && v != r.db_instance_identifier
        @idx[v] ||= []
        @idx[v].push("db-#{r.db_instance_identifier}")
      end
    end
  end
end

pp @idx
