class RegistrationsController < Devise::RegistrationsController
  def new
    flash[:alert] = 'Registrations are not available!'
    redirect_to root_path
  end

  def create
    flash[:alert] = 'Registrations are not available!'
    redirect_to root_path
  end
end
