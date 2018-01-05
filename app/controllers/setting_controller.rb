class SettingController < ApplicationController

  before_action :render_index, only: [:tax_code_mapping]

  def index
    redirect_to action: self.action_methods.sort[1]
  end
  
  def tax_code_mapping
  end

  private
    def render_index
      render :index
    end

end
