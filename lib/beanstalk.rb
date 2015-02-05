class DelawsBeanstalk < DelawsBase
  NAME = "beanstalk"
  def initialize
    @product = Aws::ElasticBeanstalk::Client.new
    $product_prefixes["#{NAME}"] = "#{NAME}"
  end

  def describe_all
    rs = @product.describe_applications.applications
    if rs
      rs.each do |r|
        findid(r, "(environment_id)", "application_name", "#{NAME}-")
        $remove_list.push("#{NAME}-#{r.application_name}")
      end
    end
  end

  def describe(name)
    begin
      @product.describe_applications(application_names: [name.gsub(/^#{NAME}-/,"")])
      return 0
    rescue
      puts "#{Thread.current.object_id}: not_found #{name}. Skipping"
      return -1
    end
  end

  def delete(name)
    @product.delete_application(application_name: name.gsub(/^#{NAME}-/,""),  terminate_env_by_force: true)
    return 0
  end
end
