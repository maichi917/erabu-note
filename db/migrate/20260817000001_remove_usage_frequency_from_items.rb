class RemoveUsageFrequencyFromItems < ActiveRecord::Migration[7.1]
  def change
    remove_column :items, :usage_frequency, :string
  end
end
