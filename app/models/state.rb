class State < ApplicationRecord
	default_scope { order(id: :asc) }
end
