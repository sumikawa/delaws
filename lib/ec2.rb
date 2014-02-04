class DelawsEc2 < DelawsBase
  def initialize
    @prefix = ""
    @product = Aws::EC2.new
    ["i", "vol", "snap", "ami", "vpc", "subnet", "rtb", "acl", "sg", "eipalloc", "dopt", "rtbassoc"].each do |k|
      $product_prefixes[k] = "ec2"
    end
  end

  def describe_all
    rs = @product.describe_instances.reservations
    if rs
      rs.each do |r|
        instance = r.instances.first
        findid(instance, "(security_groups|_id)", "instance_id")
      end
    end
#    ['volume', 'route_table', 'network_acl', 'subnet', 'vpc'].each do |r|
    ['volume', 'route_table', 'network_acl', 'vpc'].each do |r|
      eval("@product.describe_#{r}s.first.#{r}s").each do |h|
        findid(h, "_id", "#{r}_id")
      end
    end
    @product.describe_route_tables.route_tables.each do |h|
      h.associations.each do |a|
        $remove_list.push(a.route_table_association_id)
      end
    end
    @product.describe_dhcp_options.dhcp_options.each do |h|
      $remove_list.push(h.dhcp_options_id)
    end
    @product.describe_security_groups.first.security_groups.each do |h|
      findid(h, "_id", "group_id")
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
    when /^vpc-/
      is_default = @product.describe_vpcs(vpc_ids: [name]).vpcs.first.is_default
      if is_default == true
        return -1
      else
        return 0
      end
    when /^acl-/
      is_default = @product.describe_network_acls(network_acl_ids: [name]).network_acls.first.is_default
      if is_default == true
        return -1
      else
        return 0
      end
    when /^sg-/
      name = @product.describe_security_groups(group_ids: [name]).security_groups.first.group_name
      if name == "default"
        return -1
      else
        return 0
      end
    else
      return 0
    end
    rescue => e
      pp e
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
      when /^subnet-/
        @product.delete_subnet(subnet_id: name)
      when /^vpc-/
        @product.delete_vpc(vpc_id: name)
      when /^rtbassoc-/
        @product.disassociate_route_table(association_id: name)
      when /^rtb-/
        @product.delete_route_table(route_table_id: name)
      when /^acl-/
        @product.delete_network_acl(network_acl_id: name)
      when /^sg-/
        @product.delete_security_group(group_id: name)
      when /^dopt-/
        @product.delete_dhcp_options(dhcp_options_id: name)
      when /^eipalloc-/
        @product.release_address(allocation_id: name)
      end
      return 1
    rescue => e
      pp e
    end
  end
end
