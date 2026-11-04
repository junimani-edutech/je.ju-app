enum AppPermission { createOrder, cancelOrder, recordPayment, voidPayment, createTransaction, editProduct, editCustomer, archiveCustomer, viewReports, manageMembers, editBusinessProfile, createExpense }

extension RolePermissions on String {
  Set<AppPermission> get permissions => switch (this) {
    'owner' => {...AppPermission.values},
    'admin' => AppPermission.values.toSet()..removeAll([AppPermission.manageMembers, AppPermission.editBusinessProfile]),
    'cashier' => {AppPermission.createOrder, AppPermission.recordPayment, AppPermission.editCustomer, AppPermission.createExpense},
    'order_staff' => {AppPermission.createOrder, AppPermission.editCustomer},
    'viewer' => <AppPermission>{},
    _ => <AppPermission>{},
  };
}
