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

ec2 = Aws::EC2.new

vpcs = ec2.describe_vpcs.first.vpcs
subnets = ec2.describe_subnets.first.subnets
reservations = ec2.describe_instances.reservations

idx = {}

subnets.each do |subnet|
  idx[subnet.vpc_id] ||= []
  idx[subnet.vpc_id].push(subnet.subnet_id)
end

if reservations
  reservations.each do |reservation|
    instance = reservation.instances.first
    instance.each do |k, v|
      if k =~ /_id$/
        idx[instance[k]] ||= []
        idx[instance[k]].push(instance.instance_id)
      end
    end
  end
end

pp idx
