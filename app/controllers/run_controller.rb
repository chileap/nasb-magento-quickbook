class RunController < ApplicationController
  before_action :find_run, only: [:show, :edit, :update, :destroy]

  def index
    @runs = Run.all.page(params[:page]).per(20)
    @current_failed = OrderLog.current_failed
  end

  def errors
    @error_reports = OrderLog.current_failed.all.page(params[:page]).per(20)
  end

  def show
    @success_orders = @run.run_logs.success_orders.all.page(params[:page]).per(20)
    @failed_orders = @run.run_logs.failed_orders.all.page(params[:page]).per(20)
  end

  def find_run
    @run = Run.find(params[:id])
  end
end
