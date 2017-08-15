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
  
  def row_val user, row, key
    
    key = attributes[key]
    if ImportFormat.is_const_format key
      return ImportFormat.const_val key
    end
    
    if ImportFormat.is_func_format key
      return func_val key, row
    end
    
    intVal = Integer(key)
    if intVal < 0
      return ""
    end
    
    v = row[intVal- 1]
    if v == nil
      v = ""
    end
    return v.strip
  end
  
  def self.is_malformed v
    not ImportFormat.is_acceptable_format v
  end
  
  def self.is_acceptable_format v
    ImportFormat.is_column_format v or ImportFormat.is_const_format v or ImportFormat.is_func_format v
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

  def self.is_func_format v    
    (ImportFormat.func_val_match v) != nil
  end
  
  
  
  # func_val evaluates the function described by the key
  # on the form {funcname:params}
  # Not statically defined as function may require access to 
  # the remaining import format
  def func_val key, row
    func = (ImportFormat.func_val_func_match key).to_s
    params = (ImportFormat.func_val_param_match key).to_s.split(',')
        
    case func
    when 'zip_prod'      
      # example format: {zip_prod:0-2000=glsboc,2001-5000=glspoc}
      zip = (row_val user, row, 'recipient_zip_code').to_i
      prod = match_str_intervals params, zip
      if prod
        return prod
      end      
      raise CsvImportException.new "Zip-to-prod function: no matching intervals for zip code #{zip}"
    when 'column_interval_prod'
      # example format: {column_interval_prod:6,0-2000=glsboc,2001-5000=glspoc}
      # where 6 is the input column
      column = params.shift.to_i            
      target = row[column - 1].to_i # make up for one-indexed parameters      
      prod = match_str_intervals params, target      
      if prod
        return prod
      end
      raise CsvImportException.new "Column-to-prod function: no matching intervals for input #{target}"
    else
      raise CsvImportException.new "Unknown functional import key: #{func}"      
    end    
  end
  
  def match_str_intervals str_intervals, target
    str_intervals.each do |str_interval|
      from, to = str_interval.scan(/\d+/)
      val = str_interval.match(/(?<=\=).*/).to_s
      if from.to_i <= target and target <= to.to_i
        return val
      end
    end
    return false
  end

  def cols
    return attributes.except('id','created_at','updated_at', 'user_id',
                             'is_interline', 'interline_default_mail_advertising',
                             'delimiter')
  end
  
  private
  
  # Matches a constant value key
  def self.const_val_match v
    /^{{(.*)}}$/.match v
  end
  
  # Matches an entire function definition key
  def self.func_val_match v
    /^{\w*:[\w\-\=;,\.()\[\]]*}$/.match v
  end
  
  
  # Matches the function name in a function definition key
  def self.func_val_func_match v
    /(?<={)\w*(?=:)/.match v
  end
  
  # Matches the function parameter string in a function definition key
  def self.func_val_param_match v
    /(?<=:).*(?=})/.match v
  end
  
  
end
