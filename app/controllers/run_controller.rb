class RunController < ApplicationController
  before_action :find_run, only: %i[show edit update destroy credits_memo_report sales_receipt_report]

  def index
    @runs = Run.all.page(params[:page]).per(20)
    @current_failed = OrderLog.current_failed
  end

  def settings
    
  end

  def errors
    @error_reports = OrderLog.current_failed.all.page(params[:page]).per(20)
  end

  def show
    @success_sales_receipt = @run.run_logs.sale_receipt.success_orders.all.page(params[:page]).per(20)
    @failed_sales_receipt = @run.run_logs.sale_receipt.failed_orders.all.page(params[:page]).per(20)
    @success_credits_memo = @run.run_logs.refund_receipt.success_orders.all.page(params[:page]).per(20)
    @failed_credits_memo = @run.run_logs.refund_receipt.failed_orders.all.page(params[:page]).per(20)
  end

  def sales_receipt_report
    runlogs = @run.run_logs.sale_receipt
    send_data(xlsx_report(runlogs, 'salesreceipt'), filename: "#{@run.start_date.strftime("%B-%Y")}-SalesReceipt-RunID-#{@run.id}.xls")
  end

  def credits_memo_report
    runlogs = @run.run_logs.refund_receipt
    send_data(xlsx_report(runlogs, 'refundreceipt'), filename: "#{@run.start_date.strftime("%B-%Y")}-Refund Receipts-RunID-#{@run.id}.xls")
  end

  def find_run
    @run = Run.find(params[:id] || params[:run_id])
  end

  private

  def xlsx_report(runlogs, type)
    book = Spreadsheet::Workbook.new
    book.create_worksheet
    index = 0
    title = nil
    if type == 'salesreceipt'
      title = 'Sale Receipt'
    else
      title = 'Refund Receipt'
    end
    book.worksheet(0).insert_row(index, ['Magento No.', "#{title} No.", "Order Amount" , "#{title} Amount", 'Order Status','Billing Name ', 'Error Message'])

    runlogs.map do |log|
      qbo_link = log.qbo_id
      magento_link = log.magento_id
      if !qbo_link.nil?
        qbo_link = Spreadsheet::Link.new "https://ca.qbo.intuit.com/app/#{type}?txnId=#{log.qbo_id}", log.doc_number.nil? ? log.qbo_id : log.doc_number
      end
      if Rails.env.production?
        magento_link = Spreadsheet::Link.new "https://truenorthseedbank.com/index.php/admin/96admin89x55/sales_order/view/order_id/#{log.order_id}/", log.magento_id
      else
        magento_link = Spreadsheet::Link.new "http://magento-114327-325729.cloudwaysapps.com/96admin89x55/sales_order/view/order_id/#{log.order_id}/", log.magento_id
      end
      if log.status === 'success'
        book.worksheet(0).insert_row (index + 1), [magento_link, qbo_link, log.order_amount, log.credit_amount, log.order_status, log.billing_name, '']
      else
        book.worksheet(0).insert_row (index + 1), [magento_link, 'N/A' , 'N/A', 'N/A', 'N/A', 'N/A', log.message]
      end
    end

    buffer = StringIO.new
    book.write(buffer)
    buffer.rewind
    buffer.read
  end

end
