
class FeatureExtractor  
  # for now it will just extract out the intensity
  def self.convert(image)
    temp_photo = image.export_pixels(0,0,image.columns,image.rows,'I')
    # temp_photo.map! {|pixel| pixel.to_f / QuantumRange.to_f}
    temp_photo.divide_each(QuantumRange.to_f)
    temp_photo
  end
end