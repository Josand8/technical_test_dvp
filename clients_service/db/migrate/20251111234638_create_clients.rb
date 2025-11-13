class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients do |t|
      t.string :name, null: false
      t.string :identification
      t.string :email, null: false
      t.string :address, null: true

      t.timestamps
    end

    add_index :clients, :email, unique: true
    add_index :clients, :identification, unique: true
    add_index :clients, :name
    add_index :clients, :created_at
  end
end

