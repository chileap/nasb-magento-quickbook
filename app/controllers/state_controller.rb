class StateController < ApplicationController
	def index
		@states = State.all
	end

	def update_state
		params[:state].map do |sto|
			state = State.find(sto.first)
			if(state.present?)
				state.checked = params[:state][sto.first] == '1' ? true : false
				state.save
			end
		end
		redirect_back(fallback_location: state_index_path)
		flash[:alert] = 'Update Exclude Status successfully'
	end
end
