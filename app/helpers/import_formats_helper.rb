# Helper for import format form
module ImportFormatsHelper
  def input_field_class(field_value)
    ImportFormat.is_malformed(@format[field_value.to_s]) ? 'has-error' : ''
  end
end
