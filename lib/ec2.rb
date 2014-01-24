class DelawsEc2 < DelawsBase
  def initialize
    @prefix = ""
    @product = Aws::EC2.new
  end

  def describe_all
    rs = @product.describe_instances.reservations
    if rs
      rs.each do |r|
        instance = r.instances.first
        findid(instance, "(security_groups|_id)", "instance_id")
      end
    end
#    ['vpc', 'subnet', 'volume'].each do |r|
    ['volume', 'vpc'].each do |r|
      eval("@product.describe_#{r}s.first.#{r}s").each do |h|
        findid(h, "_id", "#{r}_id")
      end
    end
    @product.describe_snapshots(owner_ids: ['self']).snapshots.each do |h|
      $remove_list.push(h.snapshot_id)
    end
    @product.describe_images(owners: ['self']).images.each do |h|
      $remove_list.push(h.image_id)
    end
  end

  def describe(name)
    begin
    case name
    when /^i-/
      state = @product.describe_instances(instance_ids: [name]).reservations.first.instances.first.state.name
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
    when /^vol-/
      state = @product.describe_volumes(volume_ids: [name]).volumes.first.state
      case state
      when "in-use"
        return 60
      else
        return 0
      end
    when /^snap-/
      state = @product.describe_snapshots(snapshot_ids: [name]).snapshots.first.state
      case state
      when "completed"
        return 0
      else
        return 60
      end
    else
      return 0
    end
    rescue
      puts "#{Thread.current.object_id}: not_found #{name}"
      return -1
    end
  end

  def delete(name)
    begin
      case name
      when /^i-/
        @product.terminate_instances(instance_ids: [name])
        return 10
      when /^vol-/
        @product.delete_volume(volume_id: name)
      when /^snap-/
        @product.delete_snapshot(snapshot_id: name)
      when /^ami-/
        @product.deregister_image(image_id: name)
      when /^vpc-/
        @product.delete_vpc(vpc_id: name)
      end
      return 1
    rescue => e
#      pp e
    end
  end
end
