module ImportFormatsHelper
  
  
  def input_field_class v
    (ImportFormat.is_malformed @format[v.to_s]) ? 'has-error' : ''
  end
  
  
end
