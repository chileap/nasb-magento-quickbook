class Store < ApplicationRecord
	default_scope { order(id: :asc) }
end
