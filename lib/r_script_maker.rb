class RScriptMaker
  attr_reader :name
  def initialize(filename)
    @script = File.new(filename,"w")
    @name = filename
  end
  
  def library(lib_name)
    @script << "library(\'#{lib_name}\')\n"
  end
  
  def load_matrix(matrix_name, matrix_file, rows, cols)
    @script << "#{matrix_name} = matrix(scan(\'#{File.expand_path(matrix_file)}\', n=#{rows*cols}),"
    @script << " #{rows}, #{cols}, byrow = TRUE)\n"
  end
  
  def load_vector(vector_name, filename, rows)
    @script << "#{vector_name} = matrix(scan(file=\'#{File.expand_path(filename)}\', what=\"\", n=#{rows}),"
    @script << " #{rows}, 1, byrow = TRUE)\n"
  end
  
  def load(file)
    @script << "load(file=\'#{File.expand_path(file)}\')\n"
  end
  
  def save(thing, file)
    @script << "save(#{thing}, file=\'#{File.expand_path(file)}\')\n"
  end
  
  def save_matrix(matrix_name, filename)
    @script << "write.table(#{matrix_name}, file=\"#{File.expand_path(filename)}\" )\n"
  end
  
  def assign(var, command)
    @script << "#{var} <- #{command}\n"
  end
  
  def command(command)
    @script << command.to_s+"\n"
  end
  
  def execute
    `r CMD BATCH #{File.expand_path(@name)} #{File.expand_path(@name)}out`
  end
  
  def quit
    @script << "q(save = \"no\")\n"
  end
  
  def close
    @script.close
  end
end