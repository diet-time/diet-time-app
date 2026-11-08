String orderStatusLabel(String status) => switch (status.toUpperCase()) {
  'PENDING_APPROVAL' || 'PENDING' => 'Pending Approval',
  'ON_HOLD' => 'On Hold',
  'CONFIRMED' => 'Confirmed',
  'REJECTED' => 'Rejected',
  'CANCELLED' => 'Cancelled',
  'ACTIVE' => 'Active',
  'COMPLETED' => 'Completed',
  'PENDING_ACTIVATION' => 'Awaiting Activation',
  'PAUSED' => 'Paused',
  'PAUSE_REQUESTED' => 'Pause requested',
  'PAUSE_SCHEDULED' => 'Pause scheduled',
  _ => 'Under Review',
};
String paymentStatusLabel(String status) => switch (status.toUpperCase()) {
  'UNPAID' => 'Unpaid',
  'PENDING' => 'Payment Pending',
  'PAID' => 'Paid',
  'PARTIALLY_PAID' => 'Partially Paid',
  'FAILED' => 'Payment Failed',
  'REFUND_PENDING' => 'Refund Under Review',
  'REFUNDED' => 'Refunded',
  'PARTIALLY_REFUNDED' => 'Partially Refunded',
  _ => 'Payment Under Review',
};

String orderPaymentLabel(String orderStatus, String paymentStatus) {
  final status = orderStatus.toUpperCase();
  final payment = paymentStatus.toUpperCase();
  if (status == 'CANCELLED' || status == 'REJECTED') {
    if (const {'PENDING', 'UNPAID', 'FAILED'}.contains(payment)) {
      return status == 'CANCELLED'
          ? 'No payment due — Cancelled'
          : 'No payment due — Rejected';
    }
    if (payment == 'PARTIALLY_PAID') {
      return 'Partially paid — Settlement under review';
    }
  }
  return paymentStatusLabel(payment);
}

String orderCustomerMessage(String status) => switch (status.toUpperCase()) {
  'CANCELLED' =>
    'This order has been cancelled. No further deliveries are scheduled.',
  'REJECTED' => 'This order has been declined. No deliveries are scheduled.',
  'PENDING_APPROVAL' || 'PENDING' || 'ON_HOLD' || 'PENDING_ACTIVATION' =>
    'Your order is awaiting confirmation. Deliveries have not been scheduled yet.',
  'COMPLETED' =>
    'This plan has been completed. Your order details are kept here.',
  'PAUSED' => 'Your plan is paused. Check your schedule for the restart date.',
  _ => 'Check your plan and delivery schedule above for the latest details.',
};

String? orderReviewMessage(String status, Map<String, dynamic> review) {
  if (const {'CANCELLED', 'COMPLETED'}.contains(status)) return null;
  if (status == 'REJECTED') {
    return review['rejectionReason'] as String? ??
        'Your order was declined by Diet Time. Please contact us for help.';
  }
  return review['holdReason'] as String? ??
      review['fulfillmentBlockedReason'] as String? ??
      (review['awaitingPayment'] == true
          ? 'Your order is confirmed and awaiting the required payment.'
          : const {'PENDING_APPROVAL', 'PENDING'}.contains(status)
          ? 'Your order has been received. Our Diet Time team will contact you shortly to confirm the order and arrange payment.'
          : null);
}
