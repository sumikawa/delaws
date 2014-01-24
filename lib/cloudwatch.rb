class DelawsCloudWatch < DelawsBase
  def initialize
    @prefix = "cloudwatch-"
    @product = Aws::CloudWatch.new
  end

  def describe_all
    rs = @product.describe_alarms.metric_alarms
    if rs
      rs.each do |r|
        findid(r, "", "alarm_name")
      end
    end
  end

  def describe(name)
    return 0
  end

  def delete(name)
    @product.delete_alarms(alarm_name: name.gsub(/^#{@prefix}/,""))
    return 0
  end
end
