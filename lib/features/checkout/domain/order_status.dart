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
  _ => 'Under Review',
};
String paymentStatusLabel(String status) => switch (status.toUpperCase()) {
  'UNPAID' => 'Unpaid',
  'PENDING' => 'Payment Pending',
  'PAID' => 'Paid',
  'FAILED' => 'Payment Failed',
  'REFUND_PENDING' => 'Refund Under Review',
  'REFUNDED' => 'Refunded',
  'PARTIALLY_REFUNDED' => 'Partially Refunded',
  _ => 'Payment Under Review',
};
