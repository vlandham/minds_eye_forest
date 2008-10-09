
class FeatureExtractor  
  # for now it will just extract out the intensity
  def self.convert(image)
    temp_photo = image.export_pixels(0,0,image.columns,image.rows,'I')
    # temp_photo.map! {|pixel| pixel.to_f / QuantumRange.to_f}
    temp_photo.divide_each_up_to_int(QuantumRange.to_f,1000.0)
    temp_photo
  end
end