def findid(resource, regex, myid)
  resource.each do |k, v|
    if k =~ /#{regex}$/ && v != eval("resource.#{myid}")
      @idx[v] ||= []
      @idx[v].push(eval("resource.#{myid}"))
    end
  end
end
