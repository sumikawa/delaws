class DelawsRedshift < DelawsBase
  def initialize
    @prefix = "redshift-"
    @redshift = Aws::Redshift.new
  end

  def describe_all
    begin
      rs = @redshift.describe_clusters.clusters
      if rs
        rs.each do |r|
          findid(r, "(_name|_id)", "cluster_identifier", @prefix)
        end
      end
    rescue
      # do nothing. may be no service in the region
    end
  end

  def describe(name)
    begin
      cluster = @redshift.describe_clusters(cluster_identifier: name.gsub(/^#{@prefix}/,"")).clusters.first
      puts "#{name}: #{cluster.cluster_status}"
      case cluster.cluster_status
      when "available"
        return 0
      else
        return 60
      end
    rescue
      return -1
    end
  end

  def delete(name)
    begin
      cluster = @redshift.delete_cluster(cluster_identifier: name.gsub(/^#{@prefix}/,""),
                                         skip_final_cluster_snapshot: false,
                                         final_cluster_snapshot_identifier: "dummy").cluster
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
