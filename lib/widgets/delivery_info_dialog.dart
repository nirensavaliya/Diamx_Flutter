import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utills/app_colors.dart';
import '../utills/app_font.dart';
import '../utills/app_toast.dart';

class DeliveryInfoDialog extends StatelessWidget {
  const DeliveryInfoDialog({
    super.key,
    required this.title,
    required this.billingCompanyName,
    required this.billingName,
    required this.billingAddress,
    required this.shippingCompanyName,
    required this.shippingAddress,
    required this.cityName,
    required this.stateName,
    required this.deliverBy,
    required this.deliverAssignBy,
    required this.deliverDate,
    required this.deliveredDate,
    required this.mailTelephoneNo,
    required this.shipTelephoneNo,
  });

  final String title;
  final String billingCompanyName;
  final String billingName;
  final String billingAddress;
  final String shippingCompanyName;
  final String shippingAddress;
  final String cityName;
  final String stateName;
  final String deliverBy;
  final String deliverAssignBy;
  final String deliverDate;
  final String deliveredDate;
  final String mailTelephoneNo;
  final String shipTelephoneNo;

  static Future<void> showForMemo({
    required BuildContext context,
    required String title,
    required String billingCompanyName,
    required String billingName,
    required String billingAddress,
    required String shippingCompanyName,
    required String shippingAddress,
    required String cityName,
    required String stateName,
    required String deliverBy,
    required String deliverAssignBy,
    required String deliverDate,
    required String deliveredDate,
    required String mailTelephoneNo,
    required String shipTelephoneNo,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => DeliveryInfoDialog(
        title: title,
        billingCompanyName: billingCompanyName,
        billingName: billingName,
        billingAddress: billingAddress,
        shippingCompanyName: shippingCompanyName,
        shippingAddress: shippingAddress,
        cityName: cityName,
        stateName: stateName,
        deliverBy: deliverBy,
        deliverAssignBy: deliverAssignBy,
        deliverDate: deliverDate,
        deliveredDate: deliveredDate,
        mailTelephoneNo: mailTelephoneNo,
        shipTelephoneNo: shipTelephoneNo,
      ),
    );
  }

  String _v(String value) {
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }

  Future<void> _openDialer(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number.trim());
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        Utils().showToast(
          context: context,
          title: 'Error',
          message: 'Unable to open dialer.',
          isSuccess: false,
        );
      }
    } catch (_) {
      if (context.mounted) {
        Utils().showToast(
          context: context,
          title: 'Error',
          message: 'Unable to open dialer.',
          isSuccess: false,
        );
      }
    }
  }

  Widget _phoneRow(BuildContext context, String label, String number) {
    return InkWell(
      onTap: () => _openDialer(context, number),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: _row(
                label,
                _v(number),
                valueColor: AppColors.primary,
              ),
            ),
            const Icon(
              Icons.call_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width - 40;
    final cityState = [
      if (cityName.trim().isNotEmpty) cityName.trim(),
      if (stateName.trim().isNotEmpty) stateName.trim(),
    ].join(', ');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth.clamp(280, 400),
            maxHeight: MediaQuery.sizeOf(context).height * 0.78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColoredBox(
                color: AppColors.primaryDark,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: FontFamily.montserratBold,
                            color: AppColors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Material(
                        color: AppColors.white.withValues(alpha: 0.12),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section('Billing'),
                      _row('Company', _v(billingCompanyName)),
                      _row('Name', _v(billingName)),
                      _row('Address', _v(billingAddress)),
                      const SizedBox(height: 10),
                      _section('Shipping'),
                      _row('Company', _v(shippingCompanyName)),
                      _row('Address', _v(shippingAddress)),
                      _row(
                        'City / State',
                        cityState.isEmpty ? '-' : cityState,
                      ),
                      const SizedBox(height: 10),
                      _section('Delivery'),
                      _row('Deliver By', _v(deliverBy)),
                      _row('Assign By', _v(deliverAssignBy)),
                      _row('Deliver Date', _v(deliverDate)),
                      _row('Delivered Date', _v(deliveredDate)),
                      const SizedBox(height: 10),
                      _section('Contact'),
                      _phoneRow(context, 'Mail Tel', mailTelephoneNo),
                      _phoneRow(context, 'Ship Tel', shipTelephoneNo),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: FontFamily.montserratMedium,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: FontFamily.montserratSemiBold,
          color: AppColors.primaryDark,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: FontFamily.montserratRegular,
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: FontFamily.montserratSemiBold,
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
