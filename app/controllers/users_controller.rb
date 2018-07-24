class UsersController < ApplicationController
  before_action :find_user, except: [:index, :new, :new_user]

  def index
    @users = User.all.page(params[:page]).per(5)
  end

  def show
    @user
  end

  def new
    @user = User.new
  end

  def new_user
    @user = User.new(user_params)
    if @user.save
      redirect_to users_path, notice: 'User has been successfully created'
    else
      render :new
    end
  end

  def edit
    @user
  end

  def update_user
    @user.update(user_params)
    if @user.save
      redirect_to users_path, notice: 'User has been successfully updated'
    else
      render :edit
    end
  end

  def update_password
    if @user.update_attributes(password_params)
      render json: @user, status: :ok
    else
      render json: @user.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.destroy
      redirect_to users_path, notice: 'User has been successfully deleted'
    else
      redirect_to users_path, notice: 'User cannot be delete'
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def find_user
    @user = User.find(params[:user_id] || params[:id])
  end
end