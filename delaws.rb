#!/usr/bin/env ruby
require 'aws-sdk-core'
require 'pp'
require 'pry'
require 'inifile'
#require 'optparse'

ini = IniFile.load(File.expand_path("~/.aws/config"))

Aws.config = {
  access_key_id: ini['default']['aws_access_key_id'],
  secret_access_key: ini['default']['aws_secret_access_key'],
  region: ini['default']['region'],
}

idx = {}

ec2 = Aws::EC2.new
['vpc', 'subnet', 'volume'].each do |r|
  eval("ec2.describe_#{r}s.first.#{r}s").each do |h|
    h.each do |k, v|
      if k =~ /_id$/ && v != eval("h.#{r}_id")
        idx[v] ||= []
        idx[v].push(eval("h.#{r}_id"))
      end
    end
  end
end

reservations = ec2.describe_instances.reservations
if reservations
  reservations.each do |reservation|
    instance = reservation.instances.first
    instance.each do |k, v|
      if k =~ /_id$/ && v != instance.instance_id
        idx[v] ||= []
        idx[v].push(instance.instance_id)
      end
    end
  end
end

elb = Aws::ElasticLoadBalancing.new
load_balancer_descriptions = elb.describe_load_balancers.load_balancer_descriptions
if load_balancer_descriptions
  load_balancer_descriptions.each do |load_balancer_description|
    load_balancer_description = load_balancer_descriptions.first
    load_balancer_description.each do |k, v|
      if k =~ /(dns_name|vpc_id)$/ && v != load_balancer_description.load_balancer_name
        puts "#{k}: #{v}, #{load_balancer_description.load_balancer_name}"
        idx[v] ||= []
        idx[v].push(load_balancer_description.load_balancer_name)
      end
    end
  end
end

pp idx
