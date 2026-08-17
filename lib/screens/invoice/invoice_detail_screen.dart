import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/invoice.dart';
import '../../providers/invoice_provider.dart';
import '../../routes/app_routes.dart';
import '../../utills/app_colors.dart';
import '../../utills/app_font.dart';
import '../../utills/app_images.dart';
import '../../widgets/app_loader.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key, required this.invoice});

  final Invoice invoice;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late Invoice _invoice;
  bool _isItemsLoading = true;
  String? _itemsError;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadItems());
  }

  Future<void> _loadItems() async {
    setState(() {
      _isItemsLoading = true;
      _itemsError = null;
    });

    try {
      final items = await context.read<InvoiceProvider>().loadInvoiceItems(
        _invoice.id,
      );
      if (!mounted) return;
      setState(() {
        _invoice = _invoice.copyWith(items: items);
        _isItemsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _itemsError = error.toString().replaceFirst('Bad state: ', '');
        _isItemsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
                Color(0xFF14634E),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -25,
                top: -28,
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.white.withValues(alpha: 0.08),
                  size: 125,
                ),
              ),
            ],
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Center(
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.12),
                ),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
          ),
        ),
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Details',
              style: TextStyle(
                fontFamily: FontFamily.montserratBold,
                color: AppColors.white,
                fontSize: 19,
              ),
            ),
            // const SizedBox(height: 4),
            // Text(
            //   _invoice.id,
            //   style: TextStyle(
            //     fontFamily: FontFamily.montserratMedium,
            //     color: AppColors.white.withValues(alpha: 0.68),
            //     fontSize: 9.5,
            //     letterSpacing: 0.8,
            //   ),
            // ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          _InvoiceHeader(invoice: _invoice),
          const SizedBox(height: 16),
          _BillingCard(invoice: _invoice),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                'Diamond Details',
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_invoice.diamondCount} Diamonds',
                  style: TextStyle(
                    fontFamily: FontFamily.montserratSemiBold,
                    color: AppColors.primary,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_itemsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _itemsError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontFamily.montserratMedium,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            )
          else if (!_isItemsLoading && _invoice.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No diamond details found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontFamily.montserratMedium,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            )
          else if (!_isItemsLoading)
            ..._invoice.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _InvoiceItemCard(item: item),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(
                color: AppColors.secondary.withValues(alpha: 0.8),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.1),
                blurRadius: 22,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.invoicePrint,
                arguments: _invoice,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.print_outlined),
              label: Text(
                'PRINT INVOICE',
                style: TextStyle(
                  fontFamily: FontFamily.montserratSemiBold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ),
        ),
        if (_isItemsLoading)
          const FullScreenLoader(message: 'Loading diamonds...'),
      ],
    );
  }
}

class _InvoiceHeader extends StatelessWidget {
  const _InvoiceHeader({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final isPending = invoice.status == InvoiceStatus.pending;
    final statusColor = isPending ? AppColors.accentDark : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF14634E)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 22,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            bottom: -35,
            child: Icon(
              Icons.receipt_long_outlined,
              color: AppColors.white.withValues(alpha: 0.08),
              size: 130,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    invoice.id,
                    style: TextStyle(
                      fontFamily: FontFamily.montserratSemiBold,
                      color: AppColors.secondary,
                      fontSize: 9,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      invoice.statusLabel,
                      style: TextStyle(
                        fontFamily: FontFamily.montserratSemiBold,
                        color: statusColor,
                        fontSize: 8.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                invoice.title,
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  color: AppColors.white,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 245,
                child: Text(
                  invoice.description,
                  style: TextStyle(
                    fontFamily: FontFamily.montserratRegular,
                    color: AppColors.white.withValues(alpha: 0.78),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillingCard extends StatelessWidget {
  const _BillingCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.secondary),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Value(label: 'Customer', value: invoice.customerName),
              ),
              Expanded(
                child: _Value(
                  label: 'Invoice Date',
                  value: _date(invoice.date),
                ),
              ),
              Expanded(
                child: _Value(label: 'Due Date', value: _date(invoice.dueDate)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1, color: AppColors.secondary),
          ),
          Row(
            children: [
              Expanded(
                child: _Value(
                  label: 'Subtotal',
                  value: _money(invoice.subtotal),
                ),
              ),
              Expanded(
                child: _Value(
                  label: 'Tax (${invoice.taxRate.toStringAsFixed(0)}%)',
                  value: _money(invoice.taxAmount),
                ),
              ),
              Expanded(
                child: _Value(
                  label: 'Grand Total',
                  value: _money(invoice.grandTotal),
                  highlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceItemCard extends StatelessWidget {
  const _InvoiceItemCard({required this.item});

  final InvoiceItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    AppImages.imgDiamond,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.stockNumber,
                      style: TextStyle(
                        fontFamily: FontFamily.montserratSemiBold,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.shape,
                      style: TextStyle(
                        fontFamily: FontFamily.montserratRegular,
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _money(item.total),
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(height: 1, color: AppColors.secondary),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _Value(
                  label: 'Carat',
                  value: item.carat.toStringAsFixed(2),
                ),
              ),
              Expanded(
                child: _Value(label: 'Color', value: item.color),
              ),
              Expanded(
                child: _Value(label: 'Clarity', value: item.clarity),
              ),
              Expanded(
                child: _Value(label: 'PPC', value: _money(item.pricePerCarat)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: FontFamily.montserratRegular,
            color: AppColors.textSecondary,
            fontSize: 8.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: FontFamily.montserratSemiBold,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _date(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
