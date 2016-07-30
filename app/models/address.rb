class Address < ActiveRecord::Base

  has_one :address_book_record
  has_one :user, :dependent => :nullify


  def company #Convenient alias
    company_name
  end

  def short_desc
    company_name.to_s + ', ' + address_line1.to_s + ', ' + zip_code.to_s + ', ' + city.to_s + ', ' + country_code.to_s
  end


  def json_url
    "/addresses/#{id}/json"
  end
end
