class Run < ApplicationRecord
  has_many :run_logs

  default_scope { order(run_date: :desc) }
end
