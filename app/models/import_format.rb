class ImportFormat < ActiveRecord::Base
  belongs_to :user
  
  enum importer: [:default, :interline]

  def complete?
    cols.values.each do |v|
      if !v
        return false
      end
    end
    return true
  end
  
  

  def min_cols
    return cols.values.max
  end

  def cols
    return attributes.except('id','created_at','updated_at', 'user_id', 'is_interline', 'interline_default_mail_advertising')
  end
  
  
end
