class AddLayoutCapacitiesToRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :rooms, :capacity_auditorium, :integer
    add_column :rooms, :capacity_u_shape, :integer
    add_column :rooms, :capacity_classroom, :integer
    add_column :rooms, :capacity_round_tables, :integer
  end
end
