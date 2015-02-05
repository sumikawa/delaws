class DelawsRds < DelawsBase
  NAME = "rds"
  def initialize
    @product = Aws::RDS::Client.new
    $product_prefixes["#{NAME}"] = "#{NAME}"
  end

  def describe_all
    rs = @product.describe_db_instances.db_instances
    if rs
      rs.each do |r|
        findid(r, "(_name|_id)", "db_instance_identifier", "#{NAME}-instance-")
      end
    end
#    rs = @product.describe_db_snapshots(filters: [{filter_name: "snapshot_type", filter_value: ["manual"]}]).db_snapshots
    rs = @product.describe_db_snapshots.db_snapshots
    if rs
      rs.each do |r|
        next if r.snapshot_type == "automated"
        findid(r, "(_name|_id)", "db_snapshot_identifier", "#{NAME}-snapshot-")
      end
    end
    rs = @product.describe_event_subscriptions.event_subscriptions_list
    if rs
      rs.each do |r|
        $remove_list.push("#{NAME}-event-#{r.cust_subscription_id}")
      end
    end
  end

  def describe(name)
    begin
      case name
      when /^#{NAME}-instance-/
        state = @product.describe_db_instances(db_instance_identifier: name.gsub(/^#{NAME}-instance-/,"")).db_instances.first.db_instance_status
        case state
        when "available"
          return 0
        else
          pp state
          return 60
        end
      when /^#{NAME}-snapshot-/
        snapshot = @product.describe_db_snapshots(db_snapshot_identifier: name.gsub(/^#{NAME}-snapshot-/,"")).first.db_snapshots.first
        if snapshot.snapshot_type == "automated"
          return -1
        end
      end
      return 0
    rescue
      puts "#{Thread.current.object_id}: not_found #{name}"
      return -1
    end
  end

  def delete(name)
    begin
      case name
      when /^#{NAME}-instance-/
        @product.delete_db_instance(db_instance_identifier: name.gsub(/^#{NAME}-instance-/,""),
                                    skip_final_snapshot: true)
        return 60
      when /^#{NAME}-snapshot-/
        @product.delete_db_snapshot(db_snapshot_identifier: name.gsub(/^#{NAME}-snapshot-/,""))
        return 1
      when /^#{NAME}-event-/
        @product.delete_event_subscription(subscription_name: name.gsub(/^#{NAME}-event-/,""))
        return 1
      end
      return 0
    rescue => e
      pp e
    end
  end
end
