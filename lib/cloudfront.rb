class DelawsCloudFront < DelawsBase
  NAME = "cloudfront"
  def initialize
    @product = Aws::CloudFront.new
    $product_prefixes["#{NAME}"] = "#{NAME}"
  end

  def describe_all
    rs = @product.list_distributions.distribution_list.items
    if rs
      rs.each do |r|
        $remove_list.push("#{NAME}-#{r.id}")
      end
    end
  end

  def describe(name)
    distribution = @product.get_distribution(id: name.gsub(/^#{NAME}-/,""))
    if distribution.distribution.status == "InProgress"
      return 120
    end
    return 0
  end

  def delete(name)
    begin
      distribution = @product.get_distribution(id: name.gsub(/^#{NAME}-/,""))
      enabled = distribution.distribution.distribution_config.enabled
      etag = distribution.etag
      if enabled == true
        distribution.distribution.distribution_config.enabled = false
        @product.update_distribution(id: name.gsub(/^#{NAME}-/,""), if_match: etag, distribution_config: distribution.distribution.distribution_config)
      else
        @product.delete_distribution(id: name.gsub(/^#{NAME}-/,""), if_match: etag)
      end
      return 0
    rescue => e
      puts e.message
    end
  end
end
