Spree::CheckoutController.class_eval do
  before_action :load_mollie_methods, only: :edit
  before_action :invalidate_mollie_payments, only: :update
  before_action :pay_with_mollie, only: :update

  def ensure_valid_state_lock_version
    if params[:order] && params[:order][:state_lock_version]
      @order.with_lock do
        unless @order.state_lock_version == params[:order].delete(:state_lock_version).to_i
          flash[:error] = Spree.t(:order_already_updated)
          redirect_to(checkout_state_path(@order.state)) && return
        end
        @order.increment!(:state_lock_version) unless params[:state] == 'payment' && payment_is_mollie?
      end
    end
  end

  private

  def payment_is_mollie?
    if current_store.code == 'global'
      pm_id = params[:order][:payments_attributes].first[:payment_method_id]
      payment_method = Spree::PaymentMethod.find(pm_id)
      payment_method && payment_method.is_a?(Spree::PaymentMethod::Mollie)
    else
      false
    end
  end

    def pay_with_mollie
      return unless params[:state] == 'payment'

      pm_id = params[:order][:payments_attributes].first[:payment_method_id]
      payment_method = Spree::PaymentMethod.find(pm_id)

      if payment_method && payment_method.is_a?(Spree::PaymentMethod::Mollie)
        status_object = MolliePaymentService.new(payment_method: payment_method,
                                                 order: @order,
                                                 method: params[:order][:payments_attributes].first[:mollie_method_id],
                                                 issuer: params[:order][:payments_attributes].first[:issuer_id],
                                                 redirect_url: mollie_check_status_url(@order)).create_payment
        if status_object.mollie_error?
          mollie_error && return
        end

        if status_object.has_error?
          flash[:error] = status_object.errors.join("\n")
          redirect_to checkout_state_path(@order.state) && return
        end
        redirect_to status_object.payment_url
      end
    end

    def load_mollie_methods
      return unless params[:state] == 'payment'

      payment_method = Spree::PaymentMethod.first
      service = MolliePaymentService.new(payment_method: payment_method)

      @payment_methods = service.payment_methods
      @issuers = service.issuers
    end

    def mollie_error(e = nil)
      @order.errors[:base] << "Mollie error #{e.try(:message)}"
      render :edit
    end

    def invalidate_mollie_payments
      return unless params[:state] == 'payment'

      # when user goes back from checkout, paypal express payments should be invalidated  to ensure standard checkout flow
      current_order.invalidate_mollie_payments
      return true
    end
end
