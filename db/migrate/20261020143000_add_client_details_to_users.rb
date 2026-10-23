class AddClientDetailsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :cnpj, :string
    add_column :users, :phone, :string
    add_index :users, :cnpj, unique: true
  end
end
