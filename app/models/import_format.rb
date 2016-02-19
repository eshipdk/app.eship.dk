class ImportFormat < ActiveRecord::Base
  belongs_to :user


  def complete?
    attributes.values.each do |v|
      if !v
        return false
      end
    end
    return true
  end


  def min_cols
    return cols.values.max + 1
  end

  def cols
    return attributes.except('id','created_at','updated_at')
  end

end
