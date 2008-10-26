class ResultReader
  def initialize(result_folder)
    require 'faster_csv'
    @results = Hash.new { |hash, key| hash[key] = Hash.new {|hash,key| hash[key] = 0.0}}
    
    @folder = result_folder
    throw "Error result folder not a directory " unless @folder and File.directory?(@folder)
    
    read_results
  end
  
  def positives
    threshold = 0.5
    pos = @results.select {|k,v| v[:pos] > v[:neg] and v[:pos] > threshold}
    pos.map! {|pos_array| pos_array[0]}
    pos.sort
    # puts pos.inspect
  end
  
  def print
    puts @results.inspect
  end
  
  def read_results
    result_files = Dir.new(@folder).to_a.reject {|f| f.to_s !~ /\.txt$/}
    result_files.map! {|rf| "#{@folder}/#{rf}"} #make them absolute paths
    result_files.each do |filename|
      FasterCSV.foreach(filename, :headers => true) do |row|
        name_pair = row.delete(0)
        throw "Error - name is nil" unless name_pair
        name = name_pair[-1]
        results = row.to_hash
        add_to_image_results(name, results)
      end
    end
    normalize_results_by(result_files.size)
    # @results.each {|ke,va| puts va.inspect}
  end #read_results
  
  def add_to_image_results(name,new_results)
    image_results = @results[name]
    new_results.each do |key,val|
      val = val.to_f
      image_results[key] += val
      # add artificial results for positive and negative groups
      if key =~ /.*negative.*/
        image_results[:neg] += val
      else
        image_results[:pos] += val
      end
    end #add_to_image_results
    
    def normalize_results_by(amount)
      amount = amount.to_f
      @results.each do |name, image_results|
        image_results.each do |key, value|
          image_results[key] = value / amount
        end
      end
    end #normalize_results_by
    
  end
  
  
  
end