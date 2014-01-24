class DelawsCloudWatch < DelawsBase
  def initialize
    @prefix = "cloudwatch-"
    @product = Aws::CloudWatch.new
  end

  def describe_all
    rs = @product.describe_alarms.metric_alarms
    if rs
      rs.each do |r|
        findid(r, "", "alarm_name", @prefix)
      end
    end
  end

  def describe(name)
    return 0
  end

  def delete(name)
    @product.delete_alarms(alarm_names: [name.gsub(/^#{@prefix}/,"")])
    return 0
  end
end
