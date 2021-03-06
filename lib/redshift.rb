class DelawsRedshift < DelawsBase
  NAME = "redshift"
  def initialize
    @product = Aws::Redshift::Client.new
    $product_prefixes["#{NAME}"] = "#{NAME}"
  end

  def describe_all
    begin
      rs = @product.describe_clusters.clusters
      if rs
        rs.each do |r|
          findid(r, "(_name|_id)", "cluster_identifier", "#{NAME}-")
        end
      end
    rescue
      # do nothing. may be no service in the region
    end
  end

  def describe(name)
    begin
      cluster = @product.describe_clusters(cluster_identifier: name.gsub(/^#{NAME}-/,"")).clusters.first
      case cluster.cluster_status
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
    begin
      cluster = @product.delete_cluster(cluster_identifier: name.gsub(/^#{NAME}-/,""),
                                         skip_final_cluster_snapshot: true).cluster
      puts "#{name}: #{cluster.cluster_status}"
      case cluster.cluster_status
      when "deleting"
        return 0
      else
        return 60
      end
    rescue => e
      puts e.message
      puts "#{Thread.current.object_id}: not_found #{name}"
      return -1
    end
  end
end
