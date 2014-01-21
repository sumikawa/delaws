def findid(resource, regex, myid)
  resource.each do |k, v|
    if v.kind_of?(Array)
      findid_a(v, regex, myid)
    elsif v.kind_of?(Hash)
      puts "Hash exists on #{k}"
    elsif k =~ /#{regex}$/ && v != eval("resource.#{myid}")
      @idx[v] ||= []
      @idx[v].push(eval("resource.#{myid}"))
    else
      puts "#{myid}: #{k}: #{v}"
    end
  end
end

def findid_a(resource, regex, myid)
  resource.each do |k|
    findid(k, regex, myid)
  end
end
