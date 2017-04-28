class RunLog < ApplicationRecord
  belongs_to :run

  validates_inclusion_of :status, in: %w[failed success]

  def self.failed_orders
    where(status: 'failed')
  end

  def self.success_orders
    where(status: 'success')
  end
end
