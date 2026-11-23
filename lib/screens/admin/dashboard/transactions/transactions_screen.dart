import 'package:diamax_flutter/utills/app_colors.dart';
import 'package:diamax_flutter/utills/app_font.dart';
import 'package:flutter/material.dart';

import '../CommonScaffold.dart';

enum TransactionType { sale, memo, hold }

class TransactionItem {
  final TransactionType type;
  final String code;
  final String date;
  final String party;
  final String amount;

  const TransactionItem({
    required this.type,
    required this.code,
    required this.date,
    required this.party,
    required this.amount,
  });
}

class TransactionsScreen extends StatefulWidget {
  final VoidCallback? onBackTap;

  const TransactionsScreen({super.key, this.onBackTap});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int selectedTab = 0;

  final Color blue = AppColors.primary;
  final Color orange = AppColors.accentDark;
  final Color purple = AppColors.primaryLight;

  static const List<String> _tabs = ['All', 'Sales', 'Memo', 'Hold'];

  Color get _textPrimary => AppColors.textPrimary;

  Color get _textSecondary => AppColors.textSecondary;

  Color get _borderColor => AppColors.secondary.withValues(alpha: 0.85);

  final List<TransactionItem> _items = const [
    TransactionItem(
      type: TransactionType.sale,
      code: 'PS/1473',
      date: '30/11/2026',
      party: 'AKL Jewellers',
      amount: '₹2,45,000',
    ),
    TransactionItem(
      type: TransactionType.memo,
      code: 'M/954',
      date: '30/11/2026',
      party: 'XYZ Diamonds',
      amount: '₹85,000',
    ),
    TransactionItem(
      type: TransactionType.hold,
      code: 'H/203',
      date: '30/11/2026',
      party: 'Ramesh Gems',
      amount: '₹1,20,000',
    ),
    TransactionItem(
      type: TransactionType.sale,
      code: 'PS/1472',
      date: '30/11/2026',
      party: 'Pooja Jewellery',
      amount: '₹3,10,000',
    ),
    TransactionItem(
      type: TransactionType.memo,
      code: 'M/953',
      date: '30/11/2026',
      party: 'Shree Gems',
      amount: '₹75,000',
    ),
    TransactionItem(
      type: TransactionType.sale,
      code: 'PS/1471',
      date: '30/11/2026',
      party: 'Diamond Mart',
      amount: '₹1,75,000',
    ),
  ];

  List<TransactionItem> get _filtered {
    switch (selectedTab) {
      case 1:
        return _items.where((e) => e.type == TransactionType.sale).toList();
      case 2:
        return _items.where((e) => e.type == TransactionType.memo).toList();
      case 3:
        return _items.where((e) => e.type == TransactionType.hold).toList();
      default:
        return _items;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return CommonScaffold(
      title: 'Transactions',
      showBack: false,

      // Return to Dashboard through the parent navigation controller.
      onBackTap: widget.onBackTap,

      actions: [AppBarAction.filter(onTap: () {})],
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: _buildTabs(),
            ),
            Expanded(
              child: list.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 115),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _transactionCard(list[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // TABS

  Widget _buildTabs() {
    return Row(
      children: List.generate(_tabs.length, (i) {
        final selected = selectedTab == i;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == _tabs.length - 1 ? 0 : 10),
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? null : AppColors.surface,
                  gradient: selected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.accent, AppColors.primaryLight],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? Colors.transparent : _borderColor,
                  ),
                ),
                child: Text(
                  _tabs[i],
                  style: TextStyle(
                    fontFamily: selected
                        ? FontFamily.montserratBold
                        : FontFamily.montserratSemiBold,
                    color: selected ? Colors.white : _textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // CARD

  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _borderColor),
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryDark.withValues(alpha: 0.045),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Color _colorFor(TransactionType t) {
    switch (t) {
      case TransactionType.sale:
        return blue;
      case TransactionType.memo:
        return purple;
      case TransactionType.hold:
        return orange;
    }
  }

  IconData _iconFor(TransactionType t) {
    switch (t) {
      case TransactionType.sale:
        return Icons.shopping_cart_rounded;
      case TransactionType.memo:
        return Icons.description_rounded;
      case TransactionType.hold:
        return Icons.hourglass_bottom_rounded;
    }
  }

  String _labelFor(TransactionType t) {
    switch (t) {
      case TransactionType.sale:
        return 'Sale';
      case TransactionType.memo:
        return 'Memo';
      case TransactionType.hold:
        return 'Hold';
    }
  }

  Widget _transactionCard(TransactionItem item) {
    final color = _colorFor(item.type);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        // Navigate to transaction details.
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Icon(_iconFor(item.type), color: color, size: 30),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _labelFor(item.type),
                    style: TextStyle(
                      fontFamily: FontFamily.montserratBold,
                      color: _textPrimary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.code,
                    style: TextStyle(
                      fontFamily: FontFamily.montserratSemiBold,
                      color: _textPrimary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.date} • ${item.party}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: FontFamily.montserratRegular,
                      color: _textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.amount,
              maxLines: 1,
              style: TextStyle(
                fontFamily: FontFamily.montserratBold,
                color: _textPrimary,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: _textSecondary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        'No transactions found',
        style: TextStyle(
          fontFamily: FontFamily.montserratMedium,
          color: _textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }
}
