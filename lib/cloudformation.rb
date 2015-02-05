class DelawsCloudFormation < DelawsBase
  NAME = "cloudformation"
  def initialize
    @product = Aws::CloudFormation::Client.new
    $product_prefixes["#{NAME}"] = "#{NAME}"
  end

  def describe_all
    rs = @product.describe_stacks.stacks
    if rs
      rs.each do |r|
        $remove_list.push("#{NAME}-#{r.stack_name}")
      end
    end
  end

  def describe(name)
    return 0
  end

  def delete(name)
    @product.delete_stack(stack_name: name.gsub(/^#{NAME}-/,""))
    return 0
  end
end
