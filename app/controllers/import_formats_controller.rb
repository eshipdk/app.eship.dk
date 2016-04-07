class ImportFormatsController < ApplicationController
  before_filter :authenticate_admin

  def edit_for_user
    user = User.find params[:id]
    if user.import_format
      f = user.import_format
    else
      f = ImportFormat.new
      f.user = user
      f.save
    end

    redirect_to edit_import_format_path(f)
  end

  def edit
    @format = ImportFormat.find params[:id]
  end

  def update
    format = ImportFormat.find params[:id]
    
    format.interline_default_mail_advertising = (params[:interline_default_mail_advertising])
    format.importer = ImportFormat.importers[params[:importer]]
    format.update format_params


    redirect_to '/users'
  end

  private

  def format_params
    params.require(:import_format)
      .permit(
              :importer, :interline_default_mail_advertising, :return, :product_code, :package_height,
              :package_length, :package_width, :package_weight,
              :sender_company_name, :sender_attention,
              :sender_address_line1, :sender_address_line2,
              :sender_zip_code, :sender_city, :sender_country_code,
              :sender_phone_number, :sender_email,
              :recipient_company_name, :recipient_attention,
              :recipient_address_line1, :recipient_address_line2,
              :recipient_zip_code, :recipient_city, :recipient_country_code,
              :recipient_phone_number, :recipient_email, :description,
              :amount, :reference, :parcelshop_id, :label_action, :remarks
              )
  end

end
