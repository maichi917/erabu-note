class RemoveFinishReasonFromUsageLogs < ActiveRecord::Migration[7.1]
  def change
    remove_index :usage_logs, :finish_reason

    remove_column :usage_logs, :finish_reason, :string
    remove_column :usage_logs, :discontinued_reason, :text
  end
end
