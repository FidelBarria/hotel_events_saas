class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.string :name
      t.integer :capacity
      t.decimal :hourly_rate
      t.text :description

      t.timestamps
    end
  end
end
