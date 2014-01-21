def findid(resource, regex, myid)
  findid_h(resource, resource, regex, myid)
end

def findid_h(orig_resource, resource, regex, myid)
  resource.each do |k, v|
    if v.kind_of?(Hash)
      findid_h(orig_resource, v, regex, myid)
    elsif k =~ /#{regex}$/ && v != eval("orig_resource.#{myid}")
      if v.kind_of?(Array)
        v.each do |i|
          @idx[i] ||= []
          @idx[i].push(eval("orig_resource.#{myid}"))
        end
      elsif
        @idx[v] ||= []
        @idx[v].push(eval("orig_resource.#{myid}"))
      end
      puts "*** #{myid}: #{k}: #{v}" if @opt[:debug] == true
    elsif v.kind_of?(Array)
      findid_a(orig_resource, v, regex, myid)
    else
      puts "#{myid}: #{k}: #{v}" if @opt[:debug] == true
    end
  end
end

def findid_a(orig_resource, resource, regex, myid)
  resource.each do |i|
    if i.kind_of?(Array)
      puts "Array exists on #{i}" if @opt[:debug] == true
    elsif i.kind_of?(String)
      puts "String exists on #{i}" if @opt[:debug] == true
    else
      findid_h(orig_resource, i, regex, myid)
    end
  end
end
