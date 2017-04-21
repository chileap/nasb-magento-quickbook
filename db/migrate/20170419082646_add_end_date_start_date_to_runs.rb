class AddEndDateStartDateToRuns < ActiveRecord::Migration[5.0]
  def change
    add_column :runs, :start_date, :datetime
    add_column :runs, :end_date, :datetime
  end
end
