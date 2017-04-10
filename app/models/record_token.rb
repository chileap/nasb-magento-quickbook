class RecordToken < ApplicationRecord
  validates_inclusion_of :type_token, :in => %w( development staging production )
end
