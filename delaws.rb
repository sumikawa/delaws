#!/usr/bin/env ruby
require 'aws-sdk-core'
require 'pp'
require 'pry'
require 'inifile'
require 'optparse'
require_relative 'findid'

ini = IniFile.load(File.expand_path("~/.aws/config"))

region = nil
@opt = {}
OptionParser.new do |opt|
  opt.version = "0.1"
  opt.on('-r REGION', '--region REGION') {|v| region=v }
  opt.on('-d', '--debug') {|v| @opt[:debug] = true }
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
['db_instance', 'db_snapshot'].each do |i|
  rs = eval("rds.describe_#{i}s.#{i}s")
  if rs
    rs.each do |r|
      findid(r, "(_name|_id)", "#{i}_identifier")
    end
  end
end
rs = rds.describe_events.events
if rs
  rs.each do |r|
    findid(r, "(_name|_id)", "source_identifier")
  end
end

as = Aws::AutoScaling.new
rs = as.describe_auto_scaling_groups.auto_scaling_groups
if rs
  rs.each do |r|
    findid(r, "(vpc_zone_identifier|_name|_id)", "auto_scaling_group_name")
  end
end

cw = Aws::CloudWatch.new
rs = cw.describe_alarms.metric_alarms
if rs
  rs.each do |r|
    findid(r, "", "alarm_name")
  end
end

pp @idx
