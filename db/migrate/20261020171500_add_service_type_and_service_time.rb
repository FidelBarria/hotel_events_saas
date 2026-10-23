class AddServiceTypeAndServiceTime < ActiveRecord::Migration[8.1]
  def up
    add_column :services, :service_type, :string, default: "individual", null: false
    add_column :booking_services, :service_time, :time
    execute "UPDATE services SET service_type = 'equipment' WHERE category = 'equipment'"
  end

  def down
    remove_column :booking_services, :service_time
    remove_column :services, :service_type
  end
end
