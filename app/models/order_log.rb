class OrderLog < ApplicationRecord
  scope :current_failed, -> { joins("INNER JOIN run_logs ON (run_logs.id = order_logs.last_runlog_id) AND (run_logs.status = 'failed')") }

  def self.get_error_orders(authentication_data)
    failed_orders = current_failed
    errors_orders = {}
    failed_orders.each do |order|
      errors_order = MagentoRestApi.new.get_specific_magento_order(authentication_data, order.magento_id)
      errors_orders.merge!(errors_order)
    end
    return errors_orders
  end
end
