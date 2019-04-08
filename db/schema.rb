# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20190118103859) do

  create_table "additional_charges", force: :cascade do |t|
    t.integer  "user_id",      limit: 4
    t.integer  "invoice_id",   limit: 4
    t.integer  "shipment_id",  limit: 4
    t.decimal  "cost",                     precision: 16, scale: 2
    t.decimal  "price",                    precision: 16, scale: 2
    t.string   "product_code", limit: 255
    t.string   "description",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "additional_charges", ["invoice_id"], name: "index_additional_charges_on_invoice_id", using: :btree
  add_index "additional_charges", ["shipment_id"], name: "index_additional_charges_on_shipment_id", using: :btree
  add_index "additional_charges", ["user_id"], name: "index_additional_charges_on_user_id", using: :btree

  create_table "address_book_records", force: :cascade do |t|
    t.integer  "user_id",                limit: 4
    t.integer  "address_id",             limit: 4
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.boolean  "quick_select_sender",              default: false
    t.boolean  "quick_select_recipient",           default: false
  end

  add_index "address_book_records", ["address_id"], name: "index_address_book_records_on_address_id", using: :btree
  add_index "address_book_records", ["user_id"], name: "index_address_book_records_on_user_id", using: :btree

  create_table "addresses", force: :cascade do |t|
    t.string   "company_name",  limit: 255
    t.string   "attention",     limit: 255
    t.string   "address_line1", limit: 255
    t.string   "address_line2", limit: 255
    t.string   "zip_code",      limit: 255
    t.string   "city",          limit: 255
    t.string   "country_code",  limit: 255
    t.string   "phone_number",  limit: 255
    t.string   "email",         limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "config_values", force: :cascade do |t|
    t.string "key",   limit: 255
    t.string "value", limit: 255
  end

  create_table "gls_pricing_rows", force: :cascade do |t|
    t.string  "country_code",          limit: 255
    t.float   "i0_1",                  limit: 24
    t.float   "i1_5",                  limit: 24
    t.float   "i5_10",                 limit: 24
    t.float   "i10_15",                limit: 24
    t.float   "i15_20",                limit: 24
    t.float   "i20_30",                limit: 24
    t.integer "gls_pricing_matrix_id", limit: 4
  end

  add_index "gls_pricing_rows", ["gls_pricing_matrix_id"], name: "index_gls_pricing_rows_on_gls_pricing_matrix_id", using: :btree

  create_table "import_formats", force: :cascade do |t|
    t.integer  "user_id",                            limit: 4
    t.string   "return",                             limit: 255
    t.string   "product_code",                       limit: 255
    t.string   "package_height",                     limit: 255
    t.string   "package_length",                     limit: 255
    t.string   "package_width",                      limit: 255
    t.string   "package_weight",                     limit: 255
    t.string   "sender_company_name",                limit: 255
    t.string   "sender_attention",                   limit: 255
    t.string   "sender_address_line1",               limit: 255
    t.string   "sender_address_line2",               limit: 255
    t.string   "sender_zip_code",                    limit: 255
    t.string   "sender_city",                        limit: 255
    t.string   "sender_country_code",                limit: 255
    t.string   "sender_phone_number",                limit: 255
    t.string   "sender_email",                       limit: 255
    t.string   "recipient_company_name",             limit: 255
    t.string   "recipient_attention",                limit: 255
    t.string   "recipient_address_line1",            limit: 255
    t.string   "recipient_address_line2",            limit: 255
    t.string   "recipient_zip_code",                 limit: 255
    t.string   "recipient_city",                     limit: 255
    t.string   "recipient_country_code",             limit: 255
    t.string   "recipient_phone_number",             limit: 255
    t.string   "recipient_email",                    limit: 255
    t.datetime "created_at",                                                           null: false
    t.datetime "updated_at",                                                           null: false
    t.string   "description",                        limit: 255
    t.string   "amount",                             limit: 255
    t.string   "reference",                          limit: 255
    t.string   "parcelshop_id",                      limit: 255
    t.boolean  "interline_default_mail_advertising"
    t.integer  "importer",                           limit: 4,   default: 0
    t.string   "label_action",                       limit: 255, default: "{{print}}"
    t.string   "remarks",                            limit: 255, default: "{{}}"
    t.string   "delivery_instructions",              limit: 255, default: "{{}}"
    t.integer  "header_lines",                       limit: 4,   default: 0
    t.string   "delimiter",                          limit: 1,   default: ";"
    t.boolean  "cross_reference_flag",                           default: false
    t.string   "customs_amount",                     limit: 255, default: "{{}}"
    t.string   "customs_currency",                   limit: 255, default: "{{}}"
    t.string   "customs_code",                       limit: 255, default: "{{}}"
  end

  add_index "import_formats", ["user_id"], name: "index_import_formats_on_user_id", using: :btree

  create_table "interval_rows", force: :cascade do |t|
    t.string  "country_code",      limit: 255
    t.float   "weight_from",       limit: 24
    t.float   "weight_to",         limit: 24
    t.float   "value",             limit: 24
    t.integer "interval_table_id", limit: 4
    t.float   "default_markup",    limit: 24,  default: 0.0
  end

  add_index "interval_rows", ["interval_table_id"], name: "index_interval_rows_on_interval_table_id", using: :btree

  create_table "invoice_rows", force: :cascade do |t|
    t.integer "invoice_id",   limit: 4
    t.decimal "amount",                   precision: 16, scale: 2
    t.string  "description",  limit: 255
    t.string  "product_code", limit: 255,                          default: "unknown"
    t.integer "qty",          limit: 4,                            default: 1
    t.decimal "unit_price",               precision: 30, scale: 2, default: 0.0
    t.decimal "cost",                     precision: 16, scale: 2
  end

  add_index "invoice_rows", ["invoice_id"], name: "index_invoice_rows_on_invoice_id", using: :btree

  create_table "invoices", force: :cascade do |t|
    t.integer  "user_id",                        limit: 4
    t.decimal  "amount",                                     precision: 16, scale: 2
    t.datetime "created_at",                                                                          null: false
    t.datetime "updated_at",                                                                          null: false
    t.integer  "n_shipments",                    limit: 4
    t.boolean  "sent_to_economic",                                                    default: false
    t.decimal  "gross_amount",                               precision: 16, scale: 2, default: 0.0
    t.boolean  "captured_online",                                                     default: false
    t.integer  "economic_id",                    limit: 4
    t.boolean  "paid",                                                                default: false, null: false
    t.integer  "affiliate_id",                   limit: 4
    t.decimal  "cost",                                       precision: 16, scale: 2
    t.decimal  "profit",                                     precision: 16, scale: 2
    t.decimal  "affiliate_commission",                       precision: 16, scale: 2
    t.decimal  "house_commission",                           precision: 16, scale: 2
    t.boolean  "affiliate_commission_withdrawn",                                      default: false
    t.integer  "economic_draft_id",              limit: 4
    t.string   "pdf_download_key",               limit: 255
  end

  add_index "invoices", ["user_id"], name: "index_invoices_on_user_id", using: :btree

  create_table "markup_rows", force: :cascade do |t|
    t.integer "cost_break_id",     limit: 4
    t.integer "interval_table_id", limit: 4
    t.float   "markup",            limit: 24, default: 0.0
    t.boolean "active",                       default: false
  end

  add_index "markup_rows", ["cost_break_id"], name: "index_markup_rows_on_cost_break_id", using: :btree
  add_index "markup_rows", ["interval_table_id"], name: "index_markup_rows_on_interval_table_id", using: :btree

  create_table "packages", force: :cascade do |t|
    t.float    "width",       limit: 24
    t.float    "height",      limit: 24
    t.float    "length",      limit: 24
    t.float    "weight",      limit: 24
    t.integer  "amount",      limit: 4,                            default: 1
    t.integer  "shipment_id", limit: 4
    t.datetime "created_at",                                                   null: false
    t.datetime "updated_at",                                                   null: false
    t.decimal  "price",                   precision: 16, scale: 2
    t.decimal  "cost",                    precision: 16, scale: 2
    t.string   "title",       limit: 255
  end

  add_index "packages", ["shipment_id"], name: "index_packages_on_shipment_id", using: :btree

  create_table "pricing_schemes", force: :cascade do |t|
    t.string  "type",         limit: 255
    t.integer "pricing_type", limit: 4,     default: 1
    t.integer "user_id",      limit: 4
    t.text    "extras",       limit: 65535
  end

  add_index "pricing_schemes", ["user_id"], name: "index_pricing_schemes_on_user_id", using: :btree

  create_table "products", force: :cascade do |t|
    t.string   "product_code",        limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "name",                limit: 255
    t.string   "tracking_url_prefix", limit: 255
    t.boolean  "taxed",                           default: true
    t.boolean  "has_parcelshops",                 default: false
    t.string   "find_parcelshop_url", limit: 255
    t.string   "original_code",       limit: 255
    t.integer  "return_product_id",   limit: 4
    t.boolean  "disabled",                        default: false
    t.boolean  "is_import",                       default: false
    t.integer  "transporter_id",      limit: 4
    t.string   "internal_name",       limit: 255
  end

  add_index "products", ["transporter_id"], name: "fk_rails_1d30df8489", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,   null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "shipments", force: :cascade do |t|
    t.integer  "user_id",               limit: 4
    t.integer  "product_id",            limit: 4
    t.string   "request_id",            limit: 255
    t.string   "awb",                   limit: 255
    t.string   "cargoflux_shipment_id", limit: 255
    t.string   "document_url",          limit: 255
    t.integer  "status",                limit: 4,                              default: 0
    t.boolean  "label_pending",                                                default: false
    t.datetime "label_pending_time"
    t.integer  "sender_address_id",     limit: 4
    t.integer  "recipient_address_id",  limit: 4
    t.text     "api_response",          limit: 65535
    t.integer  "package_length",        limit: 4
    t.integer  "package_width",         limit: 4
    t.integer  "package_height",        limit: 4
    t.float    "package_weight",        limit: 24
    t.datetime "created_at",                                                                   null: false
    t.datetime "updated_at",                                                                   null: false
    t.boolean  "return"
    t.string   "description",           limit: 255
    t.integer  "amount",                limit: 4,                              default: 1
    t.string   "reference",             limit: 255
    t.string   "parcelshop_id",         limit: 255
    t.string   "callback_url",          limit: 255
    t.boolean  "invoiced",                                                     default: false
    t.integer  "invoice_id",            limit: 4
    t.integer  "label_action",          limit: 4,                              default: 0
    t.string   "remarks",               limit: 255
    t.string   "delivery_instructions", limit: 255
    t.decimal  "price",                               precision: 30, scale: 2
    t.decimal  "cost",                                precision: 30, scale: 2
    t.integer  "shipping_state",        limit: 4,                              default: 0
    t.decimal  "final_price",                         precision: 30, scale: 2
    t.decimal  "diesel_fee",                          precision: 30, scale: 2
    t.decimal  "final_diesel_fee",                    precision: 30, scale: 2
    t.boolean  "value_determined"
    t.integer  "economic_draft_id",     limit: 4
    t.datetime "label_printed_at"
    t.decimal  "customs_amount",                      precision: 10
    t.string   "customs_currency",      limit: 255
    t.string   "customs_code",          limit: 255
  end

  add_index "shipments", ["invoice_id"], name: "index_shipments_on_invoice_id", using: :btree
  add_index "shipments", ["product_id"], name: "index_shipments_on_product_id", using: :btree
  add_index "shipments", ["user_id"], name: "index_shipments_on_user_id", using: :btree

  create_table "transporters", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_products", force: :cascade do |t|
    t.integer  "user_id",         limit: 4
    t.integer  "product_id",      limit: 4
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "alias",           limit: 255
    t.string   "default_country", limit: 255
    t.float    "default_length",  limit: 24
    t.float    "default_width",   limit: 24
    t.float    "default_height",  limit: 24
    t.float    "default_weight",  limit: 24
  end

  add_index "user_products", ["product_id"], name: "index_user_products_on_product_id", using: :btree
  add_index "user_products", ["user_id"], name: "index_user_products_on_user_id", using: :btree

  create_table "user_settings", force: :cascade do |t|
    t.integer "user_id",        limit: 4
    t.float   "package_length", limit: 24
    t.float   "package_width",  limit: 24
    t.float   "package_height", limit: 24
    t.float   "package_weight", limit: 24
  end

  add_index "user_settings", ["user_id"], name: "index_user_settings_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                            limit: 255
    t.string   "encrypted_password",               limit: 255
    t.string   "salt",                             limit: 255
    t.integer  "role",                             limit: 4,                            default: 0
    t.string   "cargoflux_api_key",                limit: 255
    t.string   "eship_api_key",                    limit: 255
    t.datetime "created_at",                                                                            null: false
    t.datetime "updated_at",                                                                            null: false
    t.integer  "address_id",                       limit: 4
    t.integer  "contact_address_id",               limit: 4
    t.integer  "billing_type",                     limit: 4,                            default: 0
    t.decimal  "unit_price",                                   precision: 16, scale: 2, default: 0.0
    t.integer  "economic_customer_id",             limit: 4
    t.integer  "billing_control",                  limit: 4,                            default: 0
    t.integer  "invoice_x_days",                   limit: 4,                            default: 7
    t.integer  "invoice_x_balance",                limit: 4,                            default: 500
    t.integer  "payment_method",                   limit: 4,                            default: 0
    t.string   "epay_subscription_id",             limit: 255
    t.integer  "affiliate_id",                     limit: 4
    t.decimal  "affiliate_commission_rate",                    precision: 16, scale: 2, default: 0.5
    t.decimal  "affiliate_base_house_amount",                  precision: 16, scale: 2, default: 2.0
    t.decimal  "affiliate_minimum_invoice_amount",             precision: 16, scale: 2, default: 500.0
    t.boolean  "enable_ftp_upload",                                                     default: false
    t.string   "ftp_upload_user",                  limit: 255
    t.string   "password_reset_key",               limit: 255
    t.boolean  "invoice_failed_bookings",                                               default: false
    t.integer  "subscription_fee",                 limit: 4,                            default: 0
    t.integer  "monthly_free_labels",              limit: 4,                            default: 0
    t.integer  "monthly_free_labels_expended",     limit: 4,                            default: 0
    t.string   "economic_api_key",                 limit: 255
    t.boolean  "import_shipments_from_cf",                                              default: false
  end

  add_index "users", ["address_id"], name: "index_users_on_address_id", using: :btree

  add_foreign_key "additional_charges", "invoices"
  add_foreign_key "additional_charges", "shipments"
  add_foreign_key "additional_charges", "users"
  add_foreign_key "address_book_records", "addresses"
  add_foreign_key "address_book_records", "users"
  add_foreign_key "import_formats", "users"
  add_foreign_key "invoice_rows", "invoices"
  add_foreign_key "invoices", "users"
  add_foreign_key "packages", "shipments"
  add_foreign_key "pricing_schemes", "users"
  add_foreign_key "products", "transporters"
  add_foreign_key "shipments", "invoices"
  add_foreign_key "shipments", "products"
  add_foreign_key "shipments", "users"
  add_foreign_key "user_products", "products"
  add_foreign_key "user_products", "users"
  add_foreign_key "user_settings", "users"
  add_foreign_key "users", "addresses"
end
