class DelawsElb < DelawsBase
  NAME = "elb"
  def initialize
    @product = Aws::ElasticLoadBalancing.new
    $product_prefixes["#{NAME}"] = "#{NAME}"
  end

  def describe_all
    rs = @product.describe_load_balancers.load_balancer_descriptions
    if rs
      rs.each do |r|
        findid(r, "(security_groups|subnets|vpc_id)", "load_balancer_name", "#{NAME}-")
      end
    end
  end

  def describe(name)
    begin
      @product.describe_load_balancers(load_balancer_names: [name.gsub(/^#{NAME}-/,"")])
      return 0
    rescue
      puts "#{Thread.current.object_id}: not_found #{name}"
      return -1
    end
  end

  def delete(name)
    @product.delete_load_balancer(load_balancer_name: name.gsub(/^#{NAME}-/,""))
    return 0
  end
end
