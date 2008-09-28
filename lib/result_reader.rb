class ResultReader
  def initialize(result_filename)
    @results = Hash.new
    File.open(result_filename,"r") do |f|
      f.readline #get rid of the first line 'x'
      
      f.each do |line|
        num, value = line.split(" ")
        num.delete! "\""
        value.delete! "\""
        @results[num.to_i - 1] = value
      end #line
    end #file
  end
  
  def positives
    pos = @results.select {|k,v| v !~ /.*negative.*/}
    pos.map! {|pos_array| pos_array[0]}
    pos.sort
  end
  
  def print
    puts @results.inspect
  end
  
  
  
end