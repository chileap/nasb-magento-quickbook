class RecordToken < ApplicationRecord
  validates :access_token, presence: true
  validates :access_secret, presence: true
  validates :company_id, presence: true
  validates :token_expires_at, presence: true

  validates_inclusion_of :type_token, :in => %w( development staging production )
end
