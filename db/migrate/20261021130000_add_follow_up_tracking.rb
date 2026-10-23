class AddFollowUpTracking < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :follow_up_on, :date

    create_table :follow_up_logs do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :observation, null: false
      t.date :completed_on, null: false
      t.date :next_follow_up_on

      t.timestamps
    end
  end
end
