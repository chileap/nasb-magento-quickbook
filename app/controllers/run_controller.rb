class RunController < ApplicationController
  def index
    @runs = Run.all
    @current_failed = OrderLog.current_failed
  end

  def errors
    @error_reports = OrderLog.current_failed
  end
end
