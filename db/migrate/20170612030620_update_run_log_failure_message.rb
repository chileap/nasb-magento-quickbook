class UpdateRunLogFailureMessage < ActiveRecord::Migration[5.0]
  def change
    RunLog.failed_orders.map do |log|
      message = log.message
      if message.include?("is not existed")
        message = message.gsub("is not existed"){"not found in QBO"}
        RunLog.where(id: log.id).update_all(message: message)
      end
    end
  end
end
