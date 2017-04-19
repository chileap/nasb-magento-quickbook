class RunLog < ApplicationRecord
  belongs_to :run

  validates_inclusion_of :status, :in => %w( failed success )

  scope :failed_orders, -> { where(status: 'failed') }
  scope :success_orders, -> { where(status: 'success') }
end
