class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.integer :client_id, null: false
      t.string :invoice_number, null: false
      t.date :issue_date, null: false
      t.date :due_date
      t.decimal :subtotal, precision: 15, scale: 2, null: false
      t.decimal :tax, precision: 15, scale: 2, default: 0.0
      t.decimal :total, precision: 15, scale: 2, null: false
      t.string :status, default: 'pending'
      t.string :notes, null: true

      t.timestamps
    end

    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, :status
    add_index :invoices, :client_id
    add_index :invoices, :issue_date
    add_index :invoices, :created_at
    add_index :invoices, :due_date
  end
end

