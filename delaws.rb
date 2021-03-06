#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'aws/decider'
require 'aws-sdk'
require 'pp'
require 'pry'
require 'inifile'
require 'optparse'
require_relative 'task'
require_relative 'swf'
require_relative 'lib/base'

require_relative 'lib/autoscaling'
require_relative 'lib/beanstalk'
require_relative 'lib/cloudformation'
require_relative 'lib/cloudfront'
require_relative 'lib/cloudwatch'
require_relative 'lib/dynamodb'
require_relative 'lib/ec2'
require_relative 'lib/elb'
require_relative 'lib/elasticache'
require_relative 'lib/rds'
require_relative 'lib/redshift'

ini = IniFile.load(File.expand_path("~/.aws/config"))

profile = 'default'
region = nil
$product_prefixes = {}
$opt = {}
OptionParser.new do |opt|
  opt.banner = "Usage: #{opt.program_name} [options] REGION(e.g. us-east-1)"
  opt.version = VERSION
  opt.on('--go-ahead', 'Execute deleting') {|v| $opt[:delete] = true }
  opt.on('-p PROFILE', '--profile PROFILE', 'Specify profile') {|v| profile = "profile #{v}" }
  opt.on('-g', '--global', 'Delete global resources') {|v| $opt[:global] = true }
  opt.on('-d', '--debug', 'Debug mode') {|v| $opt[:debug] = true }
  opt.parse!(ARGV)

  if ARGV.size == 0
    puts opt.help
    exit
  end
end

region = ARGV[0]

access_key_id = ENV['AWS_ACCESS_KEY_ID'] || ini[profile]['aws_access_key_id']
abort "No access key ID specified" unless defined?(access_key_id)
secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] || ini[profile]['aws_secret_access_key'];
abort "No secret access key specified" unless defined?(secret_access_key)

Aws.config = {
  access_key_id: access_key_id,
  secret_access_key: secret_access_key,
  region: region
}

$idx = {}
$remove_list = []

puts "listing resources in #{region} region"

if $opt[:global] == true
  $cloudfront = DelawsCloudFront.new
  $cloudfront.describe_all
end

$dynamodb = DelawsDynamoDB.new
$dynamodb.describe_all

$redshift = DelawsRedshift.new
$redshift.describe_all

$beanstalk = DelawsBeanstalk.new
$beanstalk.describe_all

$cloudformation = DelawsCloudFormation.new
$cloudformation.describe_all

$as = DelawsAutoScaling.new
$as.describe_all

$elb = DelawsElb.new
$elb.describe_all

$rds = DelawsRds.new
$rds.describe_all

$ec2 = DelawsEc2.new
$ec2.describe_all

$cloudwatch = DelawsCloudWatch.new
$cloudwatch.describe_all

$elasticache = DelawsElastiCache.new
$elasticache.describe_all

pp $idx if $opt[:debug] == true

$remove_list.uniq!
if $remove_list.size == 0
  puts "there is no resources in #{region}. exit"
  exit
end

pp $remove_list

unless $opt[:delete]
  puts "please add --go-ahead option if you want to delete all of resources"
  exit
end

# for SWF
delaws_domain = "DelAws"
AWS.config(
           access_key_id: access_key_id,
           secret_access_key: secret_access_key,
           region: region
)

swf = AWS::SimpleWorkflow.new

begin
  swf_domain = swf.domains[delaws_domain]
  swf_domain.status
rescue AWS::SimpleWorkflow::Errors::UnknownResourceFault => e
  swf.domains.create(delaws_domain, "1")
end

# Get a workflow client to start the workflow
swf_client = AWS::Flow.workflow_client(swf.client, swf_domain) do
  {:from_class => "DelawsWorkflow"}
end

10.times.each do
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

$remove_list.each do |i|
  swf_client.start_execution(i)
end

puts "Waiting workflow"

loop do
  sleep 100
end

swf_domain.activity_tasks.poll($task_list) do |activity_task|
  begin
    puts "Starting an execution..."
    activity_task.record_heartbeat! :details => '25%'
    puts "25%"
    activity_task.record_heartbeat! :details => '50%'
    puts "50%"
    activity_task.record_heartbeat! :details => '75%'
    puts "50%"
    activity_task.record_heartbeat! :details => '99%'
    puts "99%"
    activity_task.record_heartbeat! :details => '100%'
    puts "finished!"
  rescue ActivityTask::CancelRequestedError
    # cleanup after ourselves
    activity_task.cancel!
  end
end
