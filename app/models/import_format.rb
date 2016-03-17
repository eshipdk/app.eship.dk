class ImportFormat < ActiveRecord::Base
  belongs_to :user
  
  enum importer: [:default, :interline]

  def complete?
    cols.values.each do |v|
      if ImportFormat.is_malformed v
        return false
      end
    end
    return true
  end
  
  

  def min_cols
    max = 0
    cols.values.each do |v|
      if ImportFormat.is_column_format v
        max = [max, Integer(v)].max
      end
    end
    max
  end
  
  def self.is_malformed v
    not ImportFormat.is_acceptable_format v
  end
  
  def self.is_acceptable_format v
    ImportFormat.is_column_format v or ImportFormat.is_const_format v
  end
  
  def self.is_const_format v
    (ImportFormat.const_val_match v) != nil
  end
  
  def self.const_val v
    res = ImportFormat.const_val_match v
    if not res
      raise 'Malformed constant: ' + v
    end
    return res[1].to_s
  end
  
  def self.is_column_format v
    true if Integer(v) rescue false
  end

  def cols
    return attributes.except('id','created_at','updated_at', 'user_id', 'is_interline', 'interline_default_mail_advertising')
  end
  
  private
  
  def self.const_val_match v
    /^{{(.*)}}$/.match v
  end
  
end
