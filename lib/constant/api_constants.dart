class ApiConstants {
  static const String baseUrl = 'https://local.diamx.net/diamx-api/';

  /// Confirm / validate product (client) id.
  static const String confirmProductId = 'confirm-product-id';
  /// Load branches for saved product id.
  static const String getAllBranch = 'get-all-branch';
  /// User login.
  static const String login = 'login';
  static const String getPartyList = 'get-party-list';

  /// User logout.
  static const String logout = 'logout';

  /// Upload print / digital signature image.
  static const String savePrintUrlPath = 'save-Print-Url-Path';

  /// Memo issue summary / list.
  static const String getMemoIssueSummaryDetail = 'get-memo-issue-summary-detail';
}
