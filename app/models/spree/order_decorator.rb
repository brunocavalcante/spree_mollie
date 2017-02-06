Spree::Order.class_eval do
  def paid_with_mollie?
    payments.valid.map(&:payment_method).compact.any? { |p| p.is_a?(Spree::PaymentMethod::Mollie) }
  end

  def invalidate_mollie_payments
    return unless paid_with_mollie?

    payments.valid.each do |payment|
      payment.destroy! if payment.payment_method.is_a?(Spree::PaymentMethod::Mollie) && payment.pending?
    end
  end
end