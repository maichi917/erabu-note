class RemovePredictionAndReminderFromItems < ActiveRecord::Migration[7.1]
  def change
    remove_index :items, :predicted_finish_on

    remove_column :items, :predicted_finish_on, :date
    remove_column :items, :reminder_first_sent_at, :datetime
    remove_column :items, :reminder_second_sent_at, :datetime
  end
end
