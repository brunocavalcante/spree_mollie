module Spree
  class MollieController < Spree::BaseController
    layout false
    respond_to :html, :js

    protect_from_forgery except: [:notify, :continue, :get_payment]

    def notify
      MolliePaymentService.new(payment_id: params[:id]).update_payment_status

      render nothing: true, status: :ok
    end

    def check_payment_status
      order = Spree::Order.find_by_number(params[:order_id])
      payment_id = order.payments.last.response_code

      paid_before = order.paid?
      MolliePaymentService.new(payment_id: payment_id).update_payment_status
      order = order.reload
      
      flash['order_completed'] = true if !paid_before && order.paid?
      
      redirect_to order.paid? ? order_path(order) : checkout_state_path(:payment)
    end

    def get_payment
      @transaction_id = params[:transaction_id]
      service = MolliePaymentService.new(id: @transaction_id)
      @mollie_payment = service.get_payment
      
      @method_names = {
        ideal: 'iDEAL', 
        creditcard: 'Creditcard', 
        mistercash: 'Bancontact', 
        sofort: 'SOFORT Banking', 
        banktransfer: 'Bank Transfer', 
        paypal: 'PayPal', 
        bitcoin: 'Bitcoin', 
        podiumcadeaukaart: 'PODIUM Cadeaukaart', 
        paysafecard: 'paysafecard', 
        kbc: 'KBC/CBC Payment Button', 
        belfius: 'Belfius Direct Net'  
      }
    end
  end
end
