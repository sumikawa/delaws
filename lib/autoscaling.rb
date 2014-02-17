class DelawsAutoScaling < DelawsBase
  NAME = "autoscaling"
  def initialize
    @product = Aws::AutoScaling.new
    $product_prefixes["#{NAME}"] = "#{NAME}"
  end

  def describe_all
    rs = @product.describe_auto_scaling_groups.auto_scaling_groups
    if rs
      rs.each do |r|
        findid(r, "(vpc_zone_identifier|_name|_id)", "auto_scaling_group_name", "#{NAME}-")
      end
    end
  end

  def describe(name)
    begin
      @product.describe_auto_scaling_groups(auto_scaling_group_names: [name.gsub(/^#{NAME}-/,"")])
      return 0
    rescue
      puts "#{Thread.current.object_id}: not_found #{name}"
      return -1
    end
  end

  def delete(name)
    @product.delete_auto_scaling_group(auto_scaling_group_name: name.gsub(/^#{NAME}-/,""), force_delete: true)
    return 0
  end
end
