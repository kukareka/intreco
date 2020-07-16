class CreateInterviewTokens < ActiveRecord::Migration[6.0]
  def change
    create_table :interview_tokens do |t|
      t.references :interview, null: false, foreign_key: true
      t.string :role
      t.string :code

      t.timestamps
    end
  end
end
