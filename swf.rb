$task_list = "delaws_task_list"

class DelawsActivity
  extend AWS::Flow::Activities

  activity :delaws_activity do
    {
      :default_task_list => $task_list, :version => "my_first_activity",
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
    :version => "1", :execution_start_to_close_timeout => 3600, :task_list => $task_list
  }
  end

  activity_client(:activity) { {:from_class => "DelawsActivity"} }

  def delaws_workflow(name)
    activity.delaws_activity(name)
  end
end
