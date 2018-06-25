class StoreController < ApplicationController
	def index
		@stores = Store.all
	end

	def update_store
		params[:store].map do |sto|
			store = Store.find(sto.first)
			if(store.present?)
				store.checked = params[:store][sto.first] == '1' ? true : false
				store.save
			end
		end
		redirect_back(fallback_location: store_index_path)
		flash[:alert] = 'Update Exclude Store successfully'
	end
end
