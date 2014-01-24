#!/usr/bin/env ruby
require 'aws/decider'
require 'aws-sdk-core'
require 'pp'
require 'pry'
require 'inifile'
require 'optparse'
require_relative 'findid'
require_relative 'task'
require_relative 'swf'
require_relative 'lib/base'
require_relative 'lib/redshift'
require_relative 'lib/elb'
require_relative 'lib/ec2'

ini = IniFile.load(File.expand_path("~/.aws/config"))

region = nil
$opt = {}
OptionParser.new do |opt|
  opt.version = VERSION
  opt.on('-r REGION', '--region REGION') {|v| region=v }
  opt.on('-d', '--debug') {|v| $opt[:debug] = true }
  opt.parse!(ARGV)
end

Aws.config = {
  access_key_id: ini['default']['aws_access_key_id'],
  secret_access_key: ini['default']['aws_secret_access_key'],
  region: region.nil? ? ini['default']['region'] : region,
}

# for AWS SWF
delaws_domain = "DelAws"
AWS.config(
  access_key_id: ini['default']['aws_access_key_id'],
  secret_access_key: ini['default']['aws_secret_access_key'],
  region: region.nil? ? ini['default']['region'] : region
)

$idx = {}
$remove_list = []

$redshift = DelawsRedshift.new
$redshift.describe_all

$elb = DelawsElb.new
$elb.describe_all

$ec2 = DelawsEc2.new
$ec2.describe_all
['vpc', 'subnet', 'volume'].each do |r|
  eval("$ec2.ec2.describe_#{r}s.first.#{r}s").each do |h|
    findid(h, "_id", "#{r}_id")
  end
end

rds = Aws::RDS.new
['db_instance', 'db_snapshot'].each do |i|
  rs = eval("rds.describe_#{i}s.#{i}s")
  if rs
    rs.each do |r|
      findid(r, "(_name|_id)", "#{i}_identifier", "db-")
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

swf = AWS::SimpleWorkflow.new

begin
  swf_domain = swf.domains.create(delaws_domain, "10")
rescue AWS::SimpleWorkflow::Errors::DomainAlreadyExistsFault => e
  swf_domain = swf.domains[delaws_domain]
end

# Get a workflow client to start the workflow
$my_workflow_client = AWS::Flow.workflow_client(swf.client, swf_domain) do
  {:from_class => "DelawsWorkflow"}
end

5.times.each do
  Thread.new do
    activity_worker = AWS::Flow::ActivityWorker.new(swf.client, swf_domain, $task_list, DelawsActivity) { {:use_forking => false} }
    puts "starting activity worker #{Thread.current.object_id}" if $opt[:debug] == true
    activity_worker.start
  end
end

Thread.new do
  worker = AWS::Flow::WorkflowWorker.new(swf.client, swf_domain, $task_list, DelawsWorkflow)
  puts "starting workflow worker #{Thread.current.object_id}" if $opt[:debug] == true
  worker.start
end

#pp $idx
pp $remove_list.uniq
puts "Starting an execution..."

$remove_list.uniq.each do |i|
  $my_workflow_client.start_execution(i)
end

puts "Waiting workflow"

loop do
  sleep 100
end
