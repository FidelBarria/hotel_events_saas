class CreateClientsAndRelinkEvents < ActiveRecord::Migration[8.1]
  def up
    create_table :clients do |t|
      t.string :name, null: false
      t.string :cnpj
      t.string :phone
      t.string :email
      t.timestamps
    end
    add_index :clients, :cnpj, unique: true

    referenced_users = if table_exists?(:events)
      " OR id IN (SELECT client_id FROM events WHERE client_id IS NOT NULL)"
    else
      ""
    end
    execute <<~SQL
      INSERT INTO clients (id, name, cnpj, phone, email, created_at, updated_at)
      SELECT id, COALESCE(NULLIF(name, ''), email), cnpj, phone, email, created_at, updated_at
      FROM users
      WHERE role = 2#{referenced_users}
    SQL

    if table_exists?(:events) && column_exists?(:events, :client_id)
      remove_foreign_key :events, :users, column: :client_id if foreign_key_exists?(:events, :users, column: :client_id)
      add_foreign_key :events, :clients, column: :client_id
    end
  end

  def down
    if table_exists?(:events) && foreign_key_exists?(:events, :clients, column: :client_id)
      remove_foreign_key :events, :clients, column: :client_id
      add_foreign_key :events, :users, column: :client_id
    end
    drop_table :clients
  end
end
