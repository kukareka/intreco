class CreateInterviews < ActiveRecord::Migration[6.0]
  def change
    create_table :interviews do |t|
      t.string :name
      t.string :status
      t.integer :room_id

      t.timestamps
    end
  end
end
