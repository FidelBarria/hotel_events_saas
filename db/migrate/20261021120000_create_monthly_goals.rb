class CreateMonthlyGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :monthly_goals do |t|
      t.references :user, null: false, foreign_key: true
      t.date :month, null: false
      t.decimal :rooms_target, precision: 12, scale: 2, null: false, default: 0
      t.decimal :equipment_target, precision: 12, scale: 2, null: false, default: 0
      t.decimal :food_beverage_target, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total_target, precision: 12, scale: 2, null: false, default: 0

      t.timestamps
    end

    add_index :monthly_goals, [:user_id, :month], unique: true
  end
end
