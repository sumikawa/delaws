#!/usr/bin/env ruby
require 'aws/decider'
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

# for AWS SWF
$SWF_DOMAIN = "DelAws"
$TASK_LIST = "delaws_task_list"
AWS.config(
  access_key_id: ini['default']['aws_access_key_id'],
  secret_access_key: ini['default']['aws_secret_access_key'],
  region: region.nil? ? ini['default']['region'] : region
)

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

class DelawsActivity
  extend AWS::Flow::Activities

  activity :delaws_activity do
    {
      :default_task_list => $TASK_LIST, :version => "my_first_activity",
      :default_task_schedule_to_start_timeout => 30,
      :default_task_start_to_close_timeout => 30
    }
  end

  def delaws_activity(name)
    puts "Hello, #{name}! I'm #{Thread.current.object_id}"
  end
end
class DelawsWorkflow
  extend AWS::Flow::Workflows

  workflow :delaws_workflow do
  {
    :version => "1", :execution_start_to_close_timeout => 3600, :task_list => $TASK_LIST
  }
  end

  activity_client(:activity) { {:from_class => "DelawsActivity"} }

  def delaws_workflow(name)
    activity.delaws_activity(name)
  end
end

$SWF = AWS::SimpleWorkflow.new

begin
  $SWF_DOMAIN = $SWF.domains.create($SWF_DOMAIN, "10")
rescue AWS::SimpleWorkflow::Errors::DomainAlreadyExistsFault => e
  $SWF_DOMAIN = $SWF.domains[$SWF_DOMAIN]
end


# Get a workflow client to start the workflow
my_workflow_client = AWS::Flow.workflow_client($SWF.client, $SWF_DOMAIN) do
  {:from_class => "DelawsWorkflow"}
end

t1 = Thread.new do
    activity_worker = AWS::Flow::ActivityWorker.new($SWF.client, $SWF_DOMAIN, $TASK_LIST, DelawsActivity) { {:use_forking => false} }
    puts "starting activity worker #{Thread.current.object_id}" if @opt[:debug] == true
    activity_worker.start
end

t2 = Thread.new do
    worker = AWS::Flow::WorkflowWorker.new($SWF.client, $SWF_DOMAIN, $TASK_LIST, DelawsWorkflow)
    puts "starting workflow worker #{Thread.current.object_id}" if @opt[:debug] == true
    worker.start
end

puts "Starting an execution..."

workflow_execution = my_workflow_client.start_execution("a")
workflow_execution = my_workflow_client.start_execution("b")
workflow_execution = my_workflow_client.start_execution("c")
workflow_execution = my_workflow_client.start_execution("d")

sleep 100
