class AddClientAndRequestDetailsToEvents < ActiveRecord::Migration[8.1]
  def change
    add_reference :events, :client, foreign_key: true unless column_exists?(:events, :client_id)
    add_column :events, :requester_name, :string
    add_column :events, :requester_phone, :string
    add_column :events, :requester_email, :string
    add_column :events, :attendee_count, :integer
    add_column :events, :setup_format, :string
  end
end
