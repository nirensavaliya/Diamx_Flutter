class ApiConstants {
  static const String baseUrl = 'https://local.diamx.net/diamx-api/';

  /// Confirm / validate product (client) id.
  static const String confirmProductId = 'confirm-product-id';
  /// Load branches for saved product id.
  static const String getAllBranch = 'get-all-branch';
  /// User login.
  static const String login = 'login';
  static const String getPartyList = 'get-party-list';
  static const String logout = 'logout';

  /// Upload print / digital signature image.
  static const String savePrintUrlPath = 'save-Print-Url-Path';

  /// Get server print PDF URL for a transaction.
  static const String getPrintUrlPath = 'get-Print-Url-Path';

  /// Available print templates for a form (Memo Issue, etc.).
  static const String getPrintListDetail = 'get-Print-List-detail';

  /// Memo issue summary / list (legacy).
  static const String getMemoIssueSummaryDetail = 'get-memo-issue-summary-detail';

  /// Memo issue delivery list / detail.
  static const String getMemoIssueDelivery = 'get-Memo-Issue-Delivery';

  /// Invoice summary / list (legacy).
  static const String getInvoiceSummaryDetail = 'get-invoice-summary-detail';

  /// Sale invoice delivery list / detail.
  static const String getSaleInvoiceDelivery = 'get-Sale-Invoice-Delivery';
}
