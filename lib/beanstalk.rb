class DelawsBeanstalk < DelawsBase
  def initialize
    @prefix = "beanstalk-"
    @product = Aws::ElasticBeanstalk.new
  end

  def describe_all
    rs = @product.describe_applications.applications
    if rs
      rs.each do |r|
        findid(r, "(environment_id)", "application_name", @prefix)
        $remove_list.push("#{@prefix}#{r.application_name}")
      end
    end
  end

  def describe(name)
    begin
      @product.describe_applications(application_names: [name.gsub(/^#{@prefix}/,"")])
      return 0
    rescue
      puts "#{Thread.current.object_id}: not_found #{name}"
      return -1
    end
  end

  def delete(name)
    @product.delete_application(application_name: name.gsub(/^#{@prefix}/,""),  terminate_env_by_force: true)
    return 0
  end
end
