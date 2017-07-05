class AddUploadOptionsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :enable_ftp_upload, :boolean, default: false
    add_column :users, :ftp_upload_user, :string
  end
end
