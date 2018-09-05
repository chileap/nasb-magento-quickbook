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
    title = nil
    date_title = nil
    if type == 'salesreceipt'
      title = 'Sale Receipt'
      date_title = 'Order Date'
    else
      title = 'Refund Receipt'
      date_title = 'Refund Date'
    end

    axlsx_package = Axlsx::Package.new 
    axlsx_package.workbook do |workbook|
      workbook.styles do |s|
        wrap_text = s.add_style :alignment => { :horizontal => :center,
                                                :vertical => :center ,
                                                :wrap_text => true}

        workbook.add_worksheet do |sheet|
          sheet.add_row ['Magento No.', "#{title} No.", "#{date_title}", "Order Amount" , "#{title} Amount", 'Order Status','Billing Name ', 'Error Message'], style: wrap_text
          index = 1
          runlogs.map do |log|
            index = index + 1
            qbo_link = log.qbo_id
            magento_link = log.magento_id

            if !qbo_link.nil?
              qbo_link = "https://ca.qbo.intuit.com/app/#{type}?txnId=#{log.qbo_id}"
              sheet.add_hyperlink :location => qbo_link, :ref => "B#{index}"
            end

            if Rails.env.production?
              magento_link = "https://truenorthseedbank.com/index.php/admin/96admin89x55/sales_order/view/order_id/#{log.order_id}/"
            else
              magento_link = "http://magento-170606-493300.cloudwaysapps.com/96admin89x55/sales_order/view/order_id/#{log.order_id}/"
            end

            sheet.add_hyperlink location: magento_link, ref: "A#{index}"

            if log.status === 'success'
              order_date = (log.order_date - 4.hours).to_datetime
              if order_date.nil?
                order_date = log.invoice_date.to_datetime
              end
              sheet.add_row [log.magento_id, log.qbo_id, order_date, log.order_amount, log.credit_amount, log.order_status, log.billing_name, '']
            else
              sheet.add_row [log.magento_id, 'N/A', 'N/A' , 'N/A', 'N/A', 'N/A', 'N/A', log.message]
            end
            # sheet.add_hyperlink :location => qbo_link, :ref => sheet.rows.second.cells.first
          end
          sheet.auto_filter = "A1:G#{runlogs.count+1}"

        end
      end
    end

    buffer = StringIO.new
    axlsx_package.use_shared_strings = true
    buffer.write(axlsx_package.to_stream.read)
    buffer.string
  end

end
