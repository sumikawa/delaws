class DelawsCloudWatch < DelawsBase
  NAME = "cloudwatch"
  def initialize
    @product = Aws::CloudWatch::Client.new
    $product_prefixes["#{NAME}"] = "#{NAME}"
  end

  def describe_all
    rs = @product.describe_alarms.metric_alarms
    if rs
      rs.each do |r|
        findid(r, "", "alarm_name", "#{NAME}-")
      end
    end
  end

  def describe(name)
    return 0
  end

  def delete(name)
    @product.delete_alarms(alarm_names: [name.gsub(/^#{NAME}-/,"")])
    return 0
  end
end
