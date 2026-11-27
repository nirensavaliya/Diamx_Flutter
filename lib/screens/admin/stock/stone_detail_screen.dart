
import 'package:flutter/material.dart';

import '../../../utills/app_colors.dart';
import '../../../utills/app_font.dart';
import '../../../utills/app_images.dart';
import '../dashboard/CommonScaffold.dart';
import 'stock_screen.dart';

// ---------------------------------------------------------------------------
// Transaction Model
// ---------------------------------------------------------------------------

class StockTransaction {
  final String date;
  final String title;
  final String amount;

  const StockTransaction({
    required this.date,
    required this.title,
    this.amount = '',
  });
}

// ---------------------------------------------------------------------------
// Stone Detail Screen
// ---------------------------------------------------------------------------

class StoneDetailScreen extends StatelessWidget {
  final StockItem item;

  final List<StockTransaction> transactions;

  const StoneDetailScreen({
    super.key,
    required this.item,
    this.transactions = const [
      StockTransaction(
        date: '30/11/2026',
        title: 'Sale / PS/1473',
        amount: '₹4,800',
      ),
      StockTransaction(
        date: '12/10/2026',
        title: 'Memo / M/0122',
        amount: '₹4,500',
      ),
    ],
  });

  static const Color _navy = Color(0xFF14213D);
  static const Color _text = Color(0xFF252D40);
  static const Color _muted = Color(0xFF858DA0);
  static const Color _border = Color(0xFFE8EBF2);
  static const Color _blue = Color(0xFF3269C8);
  static const Color _gold = Color(0xFFC99435);

  void _onShare() {
    // Add stone sharing functionality.
  }

  void _onVideo() {
    // Open stone video.
  }

  void _onCertificate() {
    // Open stone certificate.
  }

  void _on3DView() {
    // Open 3D stone view.
  }

  void _onCAD() {
    // Open CAD image.
  }

  void _onViewAll() {
    // Open complete transaction history.
  }

  void _onExportExcel() {
    // Add Excel export functionality.
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(item.status);

    return CommonScaffold(
      title: 'Stone Detail',
      showBack: true,
      actions: [
        AppBarAction(
          icon: Icons.share_rounded,
          onTap: _onShare,
        ),
      ],
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                children: [
                  // Diamond Gallery
                  _DiamondGallery(
                    on360Tap: _on3DView,
                  ),

                  const SizedBox(height: 12),

                  // Stone Details
                  _buildDetailsCard(status),

                  const SizedBox(height: 13),

                  // Certificate and Media
                  _buildMediaSection(),

                  const SizedBox(height: 15),

                  // Transaction Header
                  _buildTransactionsHeader(),

                  const SizedBox(height: 9),

                  // Transactions
                  if (transactions.isEmpty)
                    _buildEmptyTransactions()
                  else
                    ...transactions.map(
                          (transaction) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TransactionTile(
                          transaction: transaction,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Fixed Bottom Actions
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }



  Widget _buildDetailsCard(_StatusStyle status) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.035),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 5,
                top: 2,
                bottom: 2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TOP ROW
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _stoneInfoCell(
                            'STONE ID',
                            item.id,
                            valueColor: _blue,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _stoneInfoCell(
                            'SHAPE',
                            item.shape,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _stoneInfoCell(
                            'CARAT',
                            item.carat,
                          ),
                        ),
                        const SizedBox(width: 3),
                        _StatusBadge(
                          label: status.label,
                          color: status.color,
                        ),
                      ],
                    ),
                  ),

                  _stoneDivider(),

                  // SECOND ROW
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _stoneInfoCell(
                            'COLOR',
                            item.color,
                          ),
                        ),
                        Expanded(
                          child: _stoneInfoCell(
                            'CLARITY',
                            item.clarity,
                          ),
                        ),
                        Expanded(
                          child: _stoneInfoCell(
                            'CUT',
                            item.cut,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _stoneDivider(),

                  // THIRD ROW
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _stoneInfoCell(
                            'RAP RATE',
                            item.rapRate,
                          ),
                        ),
                        Expanded(
                          child: _stoneInfoCell(
                            'AMOUNT',
                            item.amount,
                            valueColor: _blue,
                            valueSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // YELLOW LEFT INDICATOR
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(
                color: const Color(0xFFF2C51D),
              ),
            ),
          ],
        ),
      ),
    );
  }

// -------------------------------------------------------------------------
// Stone Info Cell
// -------------------------------------------------------------------------

  Widget _stoneInfoCell(
      String label,
      dynamic value, {
        Color? valueColor,
        double valueSize = 11,
      }) {
    final displayValue =
    value == null || value.toString().trim().isEmpty
        ? '-'
        : value.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9299A8),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          displayValue,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.w700,
            color: valueColor ?? _navy,
          ),
        ),
      ],
    );
  }

// -------------------------------------------------------------------------
// Divider
// -------------------------------------------------------------------------

  Widget _stoneDivider() {
    return Container(
      height: 0.7,
      color: _border,
    );
  }



  // -------------------------------------------------------------------------
  // Certificate & Media Section
  // -------------------------------------------------------------------------

  Widget _buildMediaSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Certificate & Media',
            style: TextStyle(
              fontFamily: FontFamily.montserratBold,
              fontSize: 13,
              color: _text,
            ),
          ),

          const SizedBox(height: 11),

          Row(
            children: [
              Expanded(
                child: _MediaButton(
                  icon: Icons.description_outlined,
                  label: 'Certificate',
                  onTap: _onCertificate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MediaButton(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Video',
                  onTap: _onVideo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MediaButton(
                  icon: Icons.view_in_ar_rounded,
                  label: '3D View',
                  onTap: _on3DView,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MediaButton(
                  icon: Icons.diamond_outlined,
                  label: 'CAD',
                  onTap: _onCAD,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Transaction Header
  // -------------------------------------------------------------------------

  Widget _buildTransactionsHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Transaction History',
            style: TextStyle(
              fontFamily: FontFamily.montserratBold,
              fontSize: 14,
              color: _text,
            ),
          ),
        ),
        GestureDetector(
          onTap: _onViewAll,
          child: Row(
            children: [
              Text(
                'View All',
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  fontSize: 11,
                  color: _blue,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 15,
                color: _blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: const Center(
        child: Text(
          'No transactions available',
          style: TextStyle(
            fontSize: 12,
            color: _muted,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Bottom Actions
  // -------------------------------------------------------------------------

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: _border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BottomAction(
              icon: Icons.share_rounded,
              label: 'Share Details',
              background: _navy,
              foreground: Colors.white,
              onTap: _onShare,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _BottomAction(
              icon: Icons.file_download_outlined,
              label: 'Export Excel',
              background: _gold,
              foreground: Colors.white,
              onTap: _onExportExcel,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Status
  // -------------------------------------------------------------------------

  _StatusStyle _statusStyle(StockStatus status) {
    switch (status) {
      case StockStatus.available:
        return const _StatusStyle(
          'Available',
          Color(0xFF269B5B),
        );

      case StockStatus.memo:
        return const _StatusStyle(
          'Memo',
          Color(0xFFE58A32),
        );

      case StockStatus.hold:
        return const _StatusStyle(
          'Hold',
          Color(0xFF3975CB),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Diamond Gallery
// ---------------------------------------------------------------------------

class _DiamondGallery extends StatefulWidget {
  final VoidCallback? on360Tap;

  const _DiamondGallery({
    this.on360Tap,
  });

  @override
  State<_DiamondGallery> createState() => _DiamondGalleryState();
}

class _DiamondGalleryState extends State<_DiamondGallery> {
  int selectedIndex = 0;

  static const Color _gold = Color(0xFFC99435);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF26364F),
            Color(0xFF101B2E),
            Color(0xFF34445D),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 166,
            child: Stack(
              children: [
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: selectedIndex == 3
                        ? const Icon(
                      Icons.view_in_ar_rounded,
                      key: ValueKey('cad'),
                      size: 100,
                      color: Colors.white,
                    )
                        : Padding(
                      key: ValueKey(selectedIndex),
                      padding: const EdgeInsets.all(9),
                      child: Image.asset(
                        AppImages.imgDiamond,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: 2,
                  bottom: 3,
                  child: GestureDetector(
                    onTap: widget.on360Tap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.rotate_right_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 3),
                          Text(
                            '360°',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: List.generate(4, (index) {
              final isSelected = selectedIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: Container(
                    height: 43,
                    margin: EdgeInsets.only(
                      right: index == 3 ? 0 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A293F),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? _gold
                            : Colors.white.withValues(alpha: 0.28),
                        width: isSelected ? 1.7 : 0.8,
                      ),
                    ),
                    child: index == 3
                        ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.diamond_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        Text(
                          'CAD',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                        : Padding(
                      padding: const EdgeInsets.all(5),
                      child: Image.asset(
                        AppImages.imgDiamond,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail Row
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool isLast;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    this.value,
    this.isLast = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : 7,
        top: 2,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF747D91),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(
            ':',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF747D91),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value ?? '-',
              style: TextStyle(
                fontFamily: FontFamily.montserratBold,
                fontSize: 11.5,
                color: valueColor ?? const Color(0xFF252D40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Badge
// ---------------------------------------------------------------------------

class _StatusStyle {
  final String label;
  final Color color;

  const _StatusStyle(this.label, this.color);
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 125),
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// Media Button
// ---------------------------------------------------------------------------

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MediaButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F7FC),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: const Color(0xFFE5EAF4),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(0xFF3269C8),
                size: 19,
              ),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF34415A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction Tile
// ---------------------------------------------------------------------------

class _TransactionTile extends StatelessWidget {
  final StockTransaction transaction;

  const _TransactionTile({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE8EBF2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5ED),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Color(0xFF269B5B),
              size: 17,
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF293247),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  transaction.date,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF858DA0),
                  ),
                ),
              ],
            ),
          ),

          if (transaction.amount.isNotEmpty)
            Text(
              transaction.amount,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF252D40),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Action
// ---------------------------------------------------------------------------

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 42,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: foreground,
                size: 16,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  fontSize: 10.5,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
