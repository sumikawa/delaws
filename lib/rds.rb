class DelawsRds < DelawsBase
  def initialize
    @product = Aws::RDS.new
  end

  def describe_all
    rs = @product.describe_db_instances.db_instances
    if rs
      rs.each do |r|
        findid(r, "(_name|_id)", "db_instance_identifier", "rds-instance-")
      end
    end
#    rs = @product.describe_db_snapshots(filters: [{filter_name: "snapshot_type", filter_value: ["manual"]}]).db_snapshots
    rs = @product.describe_db_snapshots.db_snapshots
    if rs
      rs.each do |r|
        next if r.snapshot_type == "automated"
        findid(r, "(_name|_id)", "db_snapshot_identifier", "rds-snapshot-")
      end
    end
    rs = @product.describe_event_subscriptions.event_subscriptions_list
    if rs
      rs.each do |r|
        $remove_list.push("rds-event-#{r.cust_subscription_id}")
      end
    end
  end

  def describe(name)
    begin
      case name
      when /^rds-instance-/
        state = @product.describe_db_instances(db_instance_identifier: name.gsub(/^rds-instance-/,"")).db_instances.first.db_instance_status
        case state
        when "available"
          return 0
        else
          pp state
          return 60
        end
      when /^rds-snapshot-/
        snapshot = @product.describe_db_snapshots(db_snapshot_identifier: name.gsub(/^rds-snapshot-/,"")).first.db_snapshots.first
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
      when /^rds-instance-/
        @product.delete_db_instance(db_instance_identifier: name.gsub(/^rds-instance-/,""),
                                    skip_final_snapshot: true)
        return 60
      when /^rds-snapshot-/
        @product.delete_db_snapshot(db_snapshot_identifier: name.gsub(/^rds-snapshot-/,""))
        return 1
      when /^rds-event-/
        @product.delete_event_subscription(subscription_name: name.gsub(/^rds-event-/,""))
        return 1
      end
      return 0
    rescue => e
      pp e
    end
  end
end
