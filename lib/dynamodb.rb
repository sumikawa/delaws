class DelawsDynamoDB < DelawsBase
  NAME = "dynamodb"
  def initialize
    @product = Aws::DynamoDB::Client.new
    $product_prefixes["#{NAME}"] = "#{NAME}"
  end

  def describe_all
    rs = @product.list_tables.table_names
    if rs
      rs.each do |r|
        $remove_list.push("#{NAME}-#{r}")
      end
    end
  end

  def describe(name)
    return 0
  end

  def delete(name)
    @product.delete_table(table_name: name.gsub(/^#{NAME}-/,""))
    return 0
  end
end
