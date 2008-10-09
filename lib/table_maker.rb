
class TableMaker
  def self.make_table(data_set_name,class_set_name, raw_data)
    data_set = File.new(data_set_name, "w")
    class_set = File.new(class_set_name, "w")
    cols = nil
    rows = 0
    
    raw_data.each do |target_type, vector_array|
      rows += vector_array.size
      vector_array.each do |vector|
        cols ||= vector.size
        data_set << "#{vector.to_int_s_quick}\n"
        class_set << '"'<< target_type << '"' << "\n"
      end      
    end  
    data_set.close
    class_set.close
    [cols,rows]
  end
end