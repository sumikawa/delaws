$task_list = "delaws_task_list"

class DelawsActivity
  extend AWS::Flow::Activities

  activity :delaws_activity do
    {
      :default_task_list => $task_list,
      :version => VERSION,
      :default_task_schedule_to_start_timeout => 30,
      :default_task_start_to_close_timeout => 30,
    }
  end

  def delaws_activity(name)
    puts "#{Thread.current.object_id}: activity1, #{name}"
    if name =~ /[0-9]$/
      "next"
    else
      "restart"
    end
  end

  activity :delaws_activity2 do
    {
      :default_task_list => $task_list,
      :version => VERSION,
      :default_task_schedule_to_start_timeout => 30,
      :default_task_start_to_close_timeout => 30,
    }
  end

  def delaws_activity2(name)
    puts "#{Thread.current.object_id}: activity2, #{name}"
    "finish"
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
    puts "#{Thread.current.object_id}: called"
    return_value = activity.delaws_activity(name)
    if return_value == "next"
      puts "#{Thread.current.object_id}: call activity2 because ret = #{return_value}"
      return_value = activity.delaws_activity2(name + '0')
    end
    if return_value == "restart"
      puts "#{Thread.current.object_id}: restart because ret = #{return_value}"
      continue_as_new(name + '0')
    end
    puts "#{Thread.current.object_id}: finish"
  end
end
