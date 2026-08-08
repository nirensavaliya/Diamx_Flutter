import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/memo.dart';
import '../../providers/memo_provider.dart';
import '../../routes/app_routes.dart';
import '../../utills/app_colors.dart';
import '../../utills/app_font.dart';
import '../../utills/app_images.dart';

class MemoDetailScreen extends StatefulWidget {
  const MemoDetailScreen({super.key, required this.memo});

  final Memo memo;

  @override
  State<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends State<MemoDetailScreen> {
  late Memo _memo;
  bool _isDiamondsLoading = true;
  String? _diamondsError;

  @override
  void initState() {
    super.initState();
    _memo = widget.memo;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDiamonds());
  }

  Future<void> _loadDiamonds() async {
    setState(() {
      _isDiamondsLoading = true;
      _diamondsError = null;
    });

    try {
      final diamonds =
          await context.read<MemoProvider>().loadMemoDiamonds(_memo.id);
      if (!mounted) return;
      setState(() {
        _memo = _memo.copyWith(diamonds: diamonds);
        _isDiamondsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _diamondsError = error.toString().replaceFirst('Bad state: ', '');
        _isDiamondsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: AppColors.primaryDark,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.white,
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
                  Icons.diamond_outlined,
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
              'Memo Details',
              style: TextStyle(
                fontFamily: FontFamily.montserratBold,
                color: AppColors.white,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _memo.id,
              style: TextStyle(
                fontFamily: FontFamily.montserratMedium,
                color: AppColors.white.withValues(alpha: 0.68),
                fontSize: 9.5,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          _MemoHeader(memo: _memo),
          const SizedBox(height: 16),
          _InformationCard(memo: _memo),
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
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  '${_memo.diamonds.length} Diamonds',
                  style: TextStyle(
                    fontFamily: FontFamily.montserratSemiBold,
                    color: AppColors.primaryDark,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isDiamondsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            )
          else if (_diamondsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _diamondsError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontFamily.montserratMedium,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            )
          else
            ..._memo.diamonds.map(
              (diamond) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DiamondDetailCard(diamond: diamond),
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
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.memoPrint,
                  arguments: _memo,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.print_outlined, size: 20),
                label: Text(
                  'PRINT MEMO',
                  style: TextStyle(
                    fontFamily: FontFamily.montserratSemiBold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoHeader extends StatelessWidget {
  const _MemoHeader({required this.memo});

  final Memo memo;

  @override
  Widget build(BuildContext context) {
    final isPending = memo.status == MemoStatus.pending;
    final statusColor = isPending ? AppColors.accent : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF14634E)],
          stops: [0, 0.62, 1],
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
            right: -25,
            bottom: -38,
            child: Icon(
              Icons.diamond_outlined,
              color: AppColors.white.withValues(alpha: 0.08),
              size: 135,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      memo.id,
                      style: TextStyle(
                        fontFamily: FontFamily.montserratSemiBold,
                        color: AppColors.secondary,
                        fontSize: 9,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          memo.statusLabel,
                          style: TextStyle(
                            fontFamily: FontFamily.montserratSemiBold,
                            color: isPending
                                ? AppColors.accentDark
                                : statusColor,
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 19),
              Text(
                memo.name,
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
                  memo.description,
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

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.memo});

  final Memo memo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.055),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(21),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Memo Overview',
                  style: TextStyle(
                    fontFamily: FontFamily.montserratSemiBold,
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DetailItem(
                        label: 'Customer',
                        value: memo.customerName,
                      ),
                    ),
                    Expanded(
                      child: _DetailItem(
                        label: 'Memo Date',
                        value: _date(memo.date),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Divider(
                    height: 1,
                    color: AppColors.secondary.withValues(alpha: 0.9),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _DetailItem(label: 'PPC', value: _money(memo.ppc)),
                    ),
                    Expanded(
                      child: _DetailItem(
                        label: 'Dollar Price',
                        value: _money(memo.dollarPrice),
                      ),
                    ),
                    Expanded(
                      child: _DetailItem(
                        label: 'Total',
                        value: _money(memo.total),
                        highlight: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
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
            fontSize: 9,
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
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _DiamondDetailCard extends StatelessWidget {
  const _DiamondDetailCard({required this.diamond});

  final Diamond diamond;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.9)),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
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
                      diamond.stockNumber,
                      style: TextStyle(
                        fontFamily: FontFamily.montserratSemiBold,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      diamond.shape,
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
                _money(diamond.total),
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  color: AppColors.primaryDark,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Divider(height: 1, color: AppColors.secondary.withValues(alpha: 0.9)),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  label: 'Carat',
                  value: diamond.carat.toStringAsFixed(2),
                ),
              ),
              Expanded(
                child: _DetailItem(label: 'Color', value: diamond.color),
              ),
              Expanded(
                child: _DetailItem(label: 'Clarity', value: diamond.clarity),
              ),
              Expanded(
                child: _DetailItem(label: 'PPC', value: _money(diamond.ppc)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _date(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
