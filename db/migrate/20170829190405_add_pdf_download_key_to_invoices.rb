class AddPdfDownloadKeyToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :pdf_download_key, :string
  end
end
