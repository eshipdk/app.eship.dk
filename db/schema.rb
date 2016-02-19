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

ActiveRecord::Schema.define(version: 20160106165057) do

  create_table "addresses", force: :cascade do |t|
    t.string   "company",        limit: 255
    t.string   "attention",      limit: 255
    t.string   "address_line_1", limit: 255
    t.string   "address_line_2", limit: 255
    t.string   "address_line_3", limit: 255
    t.integer  "zip_code",       limit: 4
    t.string   "city",           limit: 255
    t.string   "country",        limit: 255
    t.string   "phone",          limit: 255
    t.string   "email",          limit: 255
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "products", force: :cascade do |t|
    t.string   "product_code", limit: 255
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "shipments", force: :cascade do |t|
    t.integer  "user_id",               limit: 4
    t.integer  "product_id",            limit: 4
    t.string   "request_id",            limit: 255
    t.string   "awb",                   limit: 255
    t.integer  "cargoflux_shipment_id", limit: 4
    t.string   "document_url",          limit: 255
    t.integer  "status",                limit: 4,   default: 0
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
  end

  add_index "shipments", ["product_id"], name: "index_shipments_on_product_id", using: :btree
  add_index "shipments", ["user_id"], name: "index_shipments_on_user_id", using: :btree

  create_table "user_products", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "product_id", limit: 4
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "user_products", ["product_id"], name: "index_user_products_on_product_id", using: :btree
  add_index "user_products", ["user_id"], name: "index_user_products_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",              limit: 255
    t.string   "encrypted_password", limit: 255
    t.string   "salt",               limit: 254
    t.integer  "role",               limit: 4,   default: 0, null: false
    t.string   "cargoflux_api_key",  limit: 254,             null: false
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_foreign_key "shipments", "products"
  add_foreign_key "shipments", "users"
  add_foreign_key "user_products", "products"
  add_foreign_key "user_products", "users"
end
