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
    puts "#{Thread.current.object_id}: check_existence: checking #{name}" if $opt[:debug] == true
    $product_prefixes.each do |k, v|
      begin
        if name =~ /^#{k}-/
          return eval("$#{v}.describe(name)")
        end
      rescue
        puts "got exception at check_existence"
      end
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
    $product_prefixes.each do |k, v|
      begin
        if name =~ /^#{k}-/
          return eval("$#{v}.delete(name)")
        end
      rescue
        puts "#{Thread.current.object_id}: delete_resource: do_nothing #{name}"
      end
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
