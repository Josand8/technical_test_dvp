# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_11_12_092641) do
  create_table "clients", force: :cascade do |t|
    t.string "name", null: false
    t.string "identification"
    t.string "email", null: false
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_clients_on_created_at"
    t.index ["email"], name: "index_clients_on_email", unique: true
    t.index ["identification"], name: "index_clients_on_identification", unique: true
    t.index ["name"], name: "index_clients_on_name"
  end

  create_table "invoices", force: :cascade do |t|
    t.integer "client_id", precision: 38, null: false
    t.string "invoice_number", null: false
    t.date "issue_date", null: false
    t.date "due_date"
    t.decimal "subtotal", precision: 15, scale: 2, null: false
    t.decimal "tax", precision: 15, scale: 2, default: "0.0"
    t.decimal "total", precision: 15, scale: 2, null: false
    t.string "status", default: "pending"
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_invoices_on_client_id"
    t.index ["created_at"], name: "index_invoices_on_created_at"
    t.index ["due_date"], name: "index_invoices_on_due_date"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
    t.index ["issue_date"], name: "index_invoices_on_issue_date"
    t.index ["status"], name: "index_invoices_on_status"
  end

end
