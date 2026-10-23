class AddCategoryToServices < ActiveRecord::Migration[8.1]
  def change
    add_column :services, :category, :string, null: false, default: "food_beverage"
  end
end
