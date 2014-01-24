class DelawsEc2 < DelawsBase
  attr_accessor :ec2
  def initialize
    @prefix = ""
    @ec2 = Aws::EC2.new
  end

  def describe_all
    rs = @ec2.describe_instances.reservations
    if rs
      rs.each do |r|
        instance = r.instances.first
        findid(instance, "(security_groups|_id)", "instance_id")
      end
    end
  end

  def describe(name)
    begin
      state = @ec2.describe_instances(instance_ids: [name]).reservations.first.instances.first.state.name
      puts "#{Thread.current.object_id}: #{name}: #{state}"
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
    rescue
      puts "#{Thread.current.object_id}: not_found #{name}"
      return -1
    end
  end

  def delete(name)
    instance = @ec2.terminate_instances(instance_ids: [name])
    return 10
  end
end
