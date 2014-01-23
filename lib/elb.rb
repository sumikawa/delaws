class DelawsElb < DelawsBase
  def initialize
    @prefix = "elb-"
    @elb = Aws::ElasticLoadBalancing.new
  end

  def describe_all
    rs = @elb.describe_load_balancers.load_balancer_descriptions
    if rs
      rs.each do |r|
        findid(r, "(security_groups|subnets|vpc_id)", "load_balancer_name", @prefix)
      end
    end
  end

  def describe(name)
    begin
      @elb.describe_load_balancers(load_balancer_names: [name.gsub(/^#{@prefix}/,"")])
      return 0
    rescue
      puts "#{Thread.current.object_id}: not_found #{name}"
      return -1
    end
  end

  def delete(name)
    @elb.delete_load_balancer(load_balancer_name: name.gsub(/^#{@prefix}/,""))
    return 0
  end
end
