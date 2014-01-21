def findid(resource, regex, myid)
  findid_h(resource, resource, regex, myid)
end

def findid_h(orig_resource, resource, regex, myid)
  resource.each do |k, v|
    if v.kind_of?(Array)
      findid_a(orig_resource, v, regex, myid)
    elsif v.kind_of?(Hash)
      puts "Hash exists on #{k}"
    elsif k =~ /#{regex}$/ && v != eval("orig_resource.#{myid}")
      @idx[v] ||= []
      @idx[v].push(eval("orig_resource.#{myid}"))
      puts "*** #{myid}: #{k}: #{v}"
    else
      puts "#{myid}: #{k}: #{v}"
    end
  end
end

def findid_a(orig_resource, resource, regex, myid)
  resource.each do |i|
    if i.kind_of?(Array)
      puts "Array exists on #{k}"
    elsif i.kind_of?(Hash)
      puts "Hash exists on #{k}"
    else
      findid_h(orig_resource, i, regex, myid)
    end
  end
end
