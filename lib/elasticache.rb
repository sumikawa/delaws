class DelawsElastiCache < DelawsBase
  NAME = "elasticache"
  def initialize
    @product = Aws::ElastiCache.new
    $product_prefixes["#{NAME}"] = "#{NAME}"
  end

  def describe_all
    rs = @product.describe_cache_clusters.cache_clusters
    if rs
      rs.each do |r|
        findid(r, "(_name|_id)", "cache_cluster_id", "#{NAME}-")
      end
    end
  end

  def describe(name)
    begin
      cluster = @product.describe_cache_clusters(cache_cluster_id: name.gsub(/^#{NAME}-/,"")).cache_clusters.first
      case cluster.cache_cluster_status
      when "available"
        return 0
      else
        puts "#{name}: status is #{cluster.cluster_status}"
        return 60
      end
    rescue
      return -1
    end
  end

  def delete(name)
    @product.delete_cache_cluster(cache_cluster_id: name.gsub(/^#{NAME}-/,""))
    return 0
  end
end
