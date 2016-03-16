class Address < ActiveRecord::Base



  def company #Convenient alias
    company_name
  end

end
