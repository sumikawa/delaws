require 'pry'

$task_list = "delaws_task_list"

class DelawsActivity
  extend AWS::Flow::Activities

  activity :check_existence do
    {
      :default_task_list => $task_list,
      :version => VERSION,
      :default_task_schedule_to_start_timeout => 30,
      :default_task_start_to_close_timeout => 30,
    }
  end

  def check_existence(name)
#    puts "#{Thread.current.object_id}: check_existence: checking #{name}"
    begin
      case name
      when /^i-/
        state = $ec2.describe_instances(instance_ids: [name]).reservations.first.instances.first.state.name
        puts "#{name}: #{state}"
        case state
        when "running"
          return 0
        when "shutting-down"
          return 60
        when "terminated"
          return -1
        else
          return 60
        end
      when /^elb-/
        return 0
      else
        begin
          $elb.describe_load_balancers(load_balancer_names: [name])
          return 0
        rescue
          puts "#{Thread.current.object_id}: check_existence: not_found #{name}"
          return -1
        end
      end
      return 0
    rescue
      puts "got exception at check_existence!"
    end
  end

  activity :delete_resource do
    {
      :default_task_list => $task_list,
      :version => VERSION,
      :default_task_schedule_to_start_timeout => 30,
      :default_task_start_to_close_timeout => 30,
    }
  end

  def delete_resource(name)
    puts "#{Thread.current.object_id}: delete_resource #{name}"
    begin
      case name
      when /^i-/
        puts "#{Thread.current.object_id}: delete_resource: terminating #{name}"
        instance = $ec2.terminate_instances(instance_ids: [name])
        return 10
      when /^elb-/
        puts "#{Thread.current.object_id}: delete_resource: deleting #{name}"
        $elb.delete_load_balancer(load_balancer_name: name.gsub(/^elb-/,""))
        return 0
      else
        puts "#{Thread.current.object_id}: delete_resource: do_nothing #{name}"
      end
    rescue
      puts "got exception at delete_resource!"
    end
  end
end

class DelawsWorkflow
  extend AWS::Flow::Workflows

  workflow :delaws_workflow do
    {
      :task_list => $task_list,
      :version => VERSION,
      :execution_start_to_close_timeout => 3600,
    }
  end

  activity_client(:activity) { {:from_class => "DelawsActivity"} }

  def delaws_workflow(name)
    timer = activity.check_existence(name)
    if timer > 0
      puts "#{Thread.current.object_id}: waiting #{timer}s #{name}"
      create_timer(timer)
      continue_as_new(name)
    elsif timer == -1
#      puts "#{Thread.current.object_id}: forcingly finish #{name}"
    else
      timer = activity.delete_resource(name)
      if timer > 0
        create_timer(timer)
        continue_as_new(name)
      end
    end
  end
end
