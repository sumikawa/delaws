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

idx = {}

['vpc', 'subnet', 'volume'].each do |r|
  eval("ec2.describe_#{r}s.first.#{r}s").each do |h|
    h.each do |k, v|
      if k =~ /_id$/ && h[k] != eval("h.#{r}_id")
        idx[h[k]] ||= []
        idx[h[k]].push(eval("h.#{r}_id"))
      end
    end
  end
end

reservations = ec2.describe_instances.reservations
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
