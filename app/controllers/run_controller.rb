class RunController < ApplicationController
  before_action :find_run, only: %i[show edit update destroy credits_memo_report sales_receipt_report]

  def index
    @runs = Run.all.page(params[:page]).per(20)
    @current_failed = OrderLog.current_failed
  end

  def errors
    @error_reports = OrderLog.current_failed.all.page(params[:page]).per(20)
  end

  def show
    @success_sales_receipt = @run.run_logs.sale_receipt.success_orders.all.page(params[:page]).per(20)
    @failed_sales_receipt = @run.run_logs.sale_receipt.failed_orders.all.page(params[:page]).per(20)
    @success_credits_memo = @run.run_logs.credit_memo.success_orders.all.page(params[:page]).per(20)
    @failed_credits_memo = @run.run_logs.credit_memo.failed_orders.all.page(params[:page]).per(20)
  end

  def sales_receipt_report
    runlogs = @run.run_logs.sale_receipt
    send_data(xlsx_report(runlogs, 'salesreceipt'), filename: "#{@run.end_date.strftime("%B-%Y")}-SalesRecript-RunID-#{@run.id}.xls")
  end

  def credits_memo_report
    runlogs = @run.run_logs.credit_memo
    send_data(xlsx_report(runlogs, 'creditmemo'), filename: "#{@run.end_date.strftime("%B-%Y")}-CreditMemo-RunID-#{@run.id}.xls")
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
      title = 'Credit Memo'
    end
    book.worksheet(0).insert_row(index, ['Magento No.', "#{title} No.", 'Error Message'])

    runlogs.map do |log|
      qbo_link = log.qbo_id
      magento_link = log.magento_id
      if !qbo_link.nil?
        qbo_link = Spreadsheet::Link.new "https://ca.qbo.intuit.com/app/#{type}?txnId=#{log.qbo_id}", log.doc_number.nil? ? log.qbo_id : log.doc_number
      end
      if Rails.env.production?
        magento_link = Spreadsheet::Link.new "https://truenorthseedbank.com/index.php/admin/96admin89x55/sales_order/view/order_id/#{log.order_id}/", log.magento_id
      else
        magento_link = Spreadsheet::Link.new "http://magento-89390-250626.cloudwaysapps.com/index.php/admin/96admin89x55/sales_order/view/order_id/#{log.order_id}/", log.magento_id
      end
      if log.status === 'success'
        book.worksheet(0).insert_row (index + 1), [magento_link, qbo_link,'']
      else
        book.worksheet(0).insert_row (index + 1), [magento_link, qbo_link, log.message]
      end
    end

    buffer = StringIO.new
    book.write(buffer)
    buffer.rewind
    buffer.read
  end

end
