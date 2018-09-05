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

ActiveRecord::Schema.define(version: 20180904075802) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "order_logs", force: :cascade do |t|
    t.string   "magento_id"
    t.string   "qbo_id"
    t.integer  "last_runlog_id"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.string   "order_id"
    t.string   "invoice_id"
    t.string   "run_type",       default: "sale_receipt"
    t.decimal  "credit_amount"
    t.string   "order_status"
    t.string   "billing_name"
  end

  create_table "record_tokens", force: :cascade do |t|
    t.string   "access_token"
    t.string   "access_secret"
    t.string   "company_id"
    t.datetime "token_expires_at"
    t.string   "type_token"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "run_logs", force: :cascade do |t|
    t.string   "magento_id"
    t.string   "qbo_id"
    t.string   "status"
    t.string   "message"
    t.integer  "run_id"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "order_id"
    t.string   "invoice_id"
    t.string   "run_type",      default: "sale_receipt"
    t.string   "doc_number"
    t.decimal  "credit_amount"
    t.string   "order_status"
    t.string   "billing_name"
    t.decimal  "order_amount",  default: "0.0"
    t.datetime "order_date"
    t.datetime "invoice_date"
    t.index ["run_id"], name: "index_run_logs_on_run_id", using: :btree
  end

  create_table "runs", force: :cascade do |t|
    t.datetime "run_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "start_date"
    t.datetime "end_date"
  end

  create_table "settings", force: :cascade do |t|
    t.string   "magento_tax_code"
    t.string   "qbo_tax_code"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "states", force: :cascade do |t|
    t.string   "name"
    t.boolean  "checked",    default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "stores", force: :cascade do |t|
    t.string   "name"
    t.boolean  "checked",    default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  end

end
