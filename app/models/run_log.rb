class RunLog < ApplicationRecord
  belongs_to :run

  validates_inclusion_of :status, in: %w[failed success]

  default_scope { order(status: :asc) }

  def self.credit_memo
    where(run_type: 'credit_memo')
  end

  def self.sale_receipt
    where(run_type: 'sale_receipt')
  end

  def self.refund_receipt
    where(run_type: 'refund_receipt')
  end

  def self.failed_orders
    where(status: 'failed')
  end

  def self.success_orders
    where(status: 'success')
  end
end
