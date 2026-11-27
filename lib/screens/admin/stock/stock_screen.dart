
import 'package:diamax_flutter/screens/admin/stock/stone_detail_screen.dart';
import 'package:flutter/material.dart';

import '../../../utills/app_colors.dart';
import '../../../utills/app_font.dart';
import '../../../utills/app_images.dart';
import '../dashboard/CommonScaffold.dart';
import 'export_to_excel_screen.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

enum StockStatus { available, memo, hold }

class StockItem {
  final String id;
  final String shape;
  final String carat;
  final String color;
  final String clarity;
  final String cut;
  final StockStatus status;

  // New fields
  final String rapRate;
  final String amount;

  const StockItem({
    required this.id,
    required this.shape,
    required this.carat,
    required this.color,
    required this.clarity,
    required this.cut,
    required this.status,
    this.rapRate = '-',
    this.amount = '-',
  });
}

// ---------------------------------------------------------------------------
// Stock Search Screen
// ---------------------------------------------------------------------------

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  static const Color _navy = Color(0xFF14233E);
  static const Color _text = Color(0xFF27334A);
  static const Color _muted = Color(0xFF858EA2);
  static const Color _border = Color(0xFFE5EAF2);
  static const Color _gold = Color(0xFFC99435);
  static const Color _blue = Color(0xFF3676D4);
  static const Color _green = Color(0xFF269B5B);
  static const Color _orange = Color(0xFFEF9B32);
  static const Color _purple = Color(0xFF9652D4);

  // -------------------------------------------------------------------------
  // Categories
  // -------------------------------------------------------------------------

  static const List<String> _categories = [
    'Polished Diamond',
    'Loose Diamond',
    'Jewellery',
    'Gems Stone',
    'Watch',
  ];

  static const List<IconData> _categoryIcons = [
    Icons.diamond_outlined,
    Icons.diamond_rounded,
    Icons.diamond,
    Icons.circle_outlined,
    Icons.watch_outlined,
  ];

  int _selectedCategory = 0;

  // -------------------------------------------------------------------------
  // Filters
  // -------------------------------------------------------------------------

  static const Map<String, List<String>> _filterOptions = {
    'Shape': [
      'Round',
      'Oval',
      'Pear',
      'Princess',
      'Emerald',
    ],
    'Size (Ct)': [
      '0.30 - 0.99',
      '1.00 - 1.49',
      '1.50 - 1.99',
      '2.00+',
    ],
    'Color': [
      'D',
      'E',
      'F',
      'G',
      'H',
    ],
    'Clarity': [
      'IF',
      'VVS1',
      'VVS2',
      'VS1',
      'VS2',
    ],
    'Cut': [
      'Ideal',
      'Excellent',
      'Very Good',
      'Good',
    ],
    'Status': [
      'All',
      'Available',
      'Memo',
      'Hold',
    ],
  };

  final Map<String, String?> _selected = {
    for (final key in _filterOptions.keys)
      key: key == 'Status' ? 'All' : null,
  };

  bool _isFilterExpanded = true;

  // -------------------------------------------------------------------------
  // Search data
  // -------------------------------------------------------------------------

  final List<StockItem> _stones = const [
    StockItem(
      id: 'D1001',
      shape: 'Round',
      carat: '1.00 ct',
      color: 'D',
      clarity: 'VVS1',
      cut: 'Excellent',
      status: StockStatus.available,
      rapRate: '\$4,800/ct',
      amount: '₹4,800',
    ),
    StockItem(
      id: 'D1002',
      shape: 'Oval',
      carat: '1.50 ct',
      color: 'E',
      clarity: 'VS1',
      cut: 'Excellent',
      status: StockStatus.memo,
      rapRate: '\$4,500/ct',
      amount: '₹6,750',
    ),
    StockItem(
      id: 'D1003',
      shape: 'Pear',
      carat: '2.00 ct',
      color: 'F',
      clarity: 'VVS2',
      cut: 'Very Good',
      status: StockStatus.hold,
      rapRate: '\$4,600/ct',
      amount: '₹9,200',
    ),
    StockItem(
      id: 'D1004',
      shape: 'Round',
      carat: '1.20 ct',
      color: 'D',
      clarity: 'VVS1',
      cut: 'Excellent',
      status: StockStatus.available,
      rapRate: '\$4,700/ct',
      amount: '₹5,640',
    ),
  ];

  final Set<String> _favorites = {};

  List<StockItem> get _filteredStones {
    return _stones.where((stone) {
      final shape = _selected['Shape'];
      final size = _selected['Size (Ct)'];
      final color = _selected['Color'];
      final clarity = _selected['Clarity'];
      final cut = _selected['Cut'];
      final status = _selected['Status'];

      if (shape != null && stone.shape != shape) {
        return false;
      }

      if (color != null && stone.color != color) {
        return false;
      }

      if (clarity != null && stone.clarity != clarity) {
        return false;
      }

      if (cut != null && stone.cut != cut) {
        return false;
      }

      if (status != null && status != 'All') {
        if (_statusLabel(stone.status) != status) {
          return false;
        }
      }

      if (size != null && !_matchesSize(stone.carat, size)) {
        return false;
      }

      return true;
    }).toList();
  }

  bool _matchesSize(String carat, String range) {
    final value = double.tryParse(
      carat.replaceAll(RegExp(r'[^0-9.]'), ''),
    );

    if (value == null) return false;

    switch (range) {
      case '0.30 - 0.99':
        return value >= 0.30 && value <= 0.99;
      case '1.00 - 1.49':
        return value >= 1.00 && value <= 1.49;
      case '1.50 - 1.99':
        return value >= 1.50 && value <= 1.99;
      case '2.00+':
        return value >= 2.00;
      default:
        return true;
    }
  }

  // -------------------------------------------------------------------------
  // Search
  // -------------------------------------------------------------------------

  void _onSearch() {
    FocusScope.of(context).unfocus();

    setState(() {
      _isFilterExpanded = false;
    });
  }

  void _clearFilters() {
    setState(() {
      for (final key in _selected.keys) {
        _selected[key] = key == 'Status' ? 'All' : null;
      }
    });
  }

  // -------------------------------------------------------------------------
  // Share
  // -------------------------------------------------------------------------

  void _onShare() {
    // Connect stone sharing functionality here.
  }

  // -------------------------------------------------------------------------
  // Export
  // -------------------------------------------------------------------------

  void _onExport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExportToExcelScreen(
          selectedRecords: _filteredStones.length,
          onDownloadTap: () {
            // Connect Excel download functionality here.
          },
          onShareTap: () {
            // Connect Excel sharing functionality here.
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------------

  void _openStone(StockItem stone) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoneDetailScreen(
          item: stone,
        ),
      ),
    );
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final stones = _filteredStones;

    final available = stones
        .where((e) => e.status == StockStatus.available)
        .length;

    final memo = stones
        .where((e) => e.status == StockStatus.memo)
        .length;

    final hold = stones
        .where((e) => e.status == StockStatus.hold)
        .length;

    return CommonScaffold(
      title: 'Stock Search',
      showBack: false,
        actions: [AppBarAction.notification(count: 3, onTap: () {})],
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
                children: [
                  // Categories
                  _buildCategoryTabs(),

                  const SizedBox(height: 12),

                  // Filters
                  _buildFilterSection(),

                  const SizedBox(height: 10),

                  // Search button
                  _buildSearchButton(),

                  const SizedBox(height: 11),

                  // Summary
                  _buildSummary(
                    total: stones.length,
                    available: available,
                    memo: memo,
                    hold: hold,
                  ),

                  const SizedBox(height: 15),

                  // Results header
                  _buildResultsHeader(stones.length),

                  const SizedBox(height: 9),

                  // Stock cards
                  if (stones.isEmpty)
                    _buildEmptyState()
                  else
                    ...stones.map(
                          (stone) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _StockCard(
                          item: stone,
                          onTap: () => _openStone(stone),
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Bottom actions
                  // _BottomActions(
                  //   onShare: _onShare,
                  //   onExport: _onExport,
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Category Tabs
  // -------------------------------------------------------------------------

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.04),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_categories.length, (index) {
          final selected = _selectedCategory == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFDDAE55),
                      Color(0xFFBC8427),
                    ],
                  )
                      : null,
                  color: selected ? null : const Color(0xFFF5F7FC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? Colors.transparent : _border,
                  ),
                ),
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _categoryIcons[index],
                    size: 17,
                    color: selected ? Colors.white : _navy,
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      _categories[index],
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: FontFamily.montserratBold,
                        fontSize: 8,
                        height: 1.1,
                        color: selected ? Colors.white : _text,
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Filter Section
  // -------------------------------------------------------------------------

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.filter_alt_rounded,
                color: _navy,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Search Filters',
                  style: TextStyle(
                    fontFamily: FontFamily.montserratBold,
                    fontSize: 11.5,
                    color: _text,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _clearFilters,
                child: Row(
                  children: [
                    Text(
                      'Clear All',
                      style: TextStyle(
                        fontFamily: FontFamily.montserratBold,
                        fontSize: 10,
                        color: _blue,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.refresh_rounded,
                      size: 13,
                      color: _blue,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isFilterExpanded = !_isFilterExpanded;
                  });
                },
                child: Icon(
                  _isFilterExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 19,
                  color: _muted,
                ),
              ),
            ],
          ),

          if (_isFilterExpanded) ...[
            const SizedBox(height: 10),
            _buildFilterGrid(),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Filter Grid
  // -------------------------------------------------------------------------

  Widget _buildFilterGrid() {
    final keys = _filterOptions.keys.toList();

    Widget buildRow(List<String> rowKeys) {
      return Row(
        children: [
          for (int i = 0; i < rowKeys.length; i++) ...[
            Expanded(
              child: _buildDropdown(rowKeys[i]),
            ),
            if (i != rowKeys.length - 1)
              const SizedBox(width: 9),
          ],
        ],
      );
    }

    return Column(
      children: [
        buildRow(keys.sublist(0, 3)),
        const SizedBox(height: 9),
        buildRow(keys.sublist(3, 6)),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Filter Dropdown
  // -------------------------------------------------------------------------

  Widget _buildDropdown(String label) {
    final selectedValue = _selected[label];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: FontFamily.montserratBold,
              fontSize: 9.5,
              color: _text,
            ),
          ),
        ),
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              isDense: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: _navy,
              ),
              hint: Text(
                label == 'Status' ? 'All' : 'Select',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: _muted,
                ),
              ),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _text,
              ),
              items: _filterOptions[label]!
                  .map(
                    (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selected[label] = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Search Button
  // -------------------------------------------------------------------------

  Widget _buildSearchButton() {
    return SizedBox(
      height: 39,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _onSearch,
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: _navy.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_rounded,
              size: 17,
            ),
            const SizedBox(width: 7),
            Text(
              'Search Stocks',
              style: TextStyle(
                fontFamily: FontFamily.montserratBold,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Summary Statistics
  // -------------------------------------------------------------------------

  Widget _buildSummary({
    required int total,
    required int available,
    required int memo,
    required int hold,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              icon: Icons.diamond_rounded,
              count: total,
              label: 'Total',
              color: _blue,
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _SummaryItem(
              icon: Icons.check_circle_rounded,
              count: available,
              label: 'Available',
              color: _green,
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _SummaryItem(
              icon: Icons.access_time_filled_rounded,
              count: memo,
              label: 'Memo',
              color: _orange,
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _SummaryItem(
              icon: Icons.pause_circle_filled_rounded,
              count: hold,
              label: 'Hold',
              color: _purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(
      width: 1,
      height: 36,
      color: _border,
    );
  }

  // -------------------------------------------------------------------------
  // Results Header
  // -------------------------------------------------------------------------

  Widget _buildResultsHeader(int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Search Results ($count Stones)',
            style: TextStyle(
              fontFamily: FontFamily.montserratBold,
              fontSize: 12.5,
              color: _text,
            ),
          ),
        ),
        GestureDetector(
          onTap: _onExport,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5ED),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFC8E6D0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.table_view_rounded,
                  size: 14,
                  color: _green,
                ),
                const SizedBox(width: 4),
                Text(
                  'Export Excel',
                  style: TextStyle(
                    fontFamily: FontFamily.montserratBold,
                    fontSize: 9.5,
                    color: _green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Empty State
  // -------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 38,
            color: _muted,
          ),
          const SizedBox(height: 9),
          Text(
            'No Stones Found',
            style: TextStyle(
              fontFamily: FontFamily.montserratBold,
              fontSize: 13,
              color: _text,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try changing your search filters.',
            style: TextStyle(
              fontSize: 10.5,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  static String _statusLabel(StockStatus status) {
    switch (status) {
      case StockStatus.available:
        return 'Available';
      case StockStatus.memo:
        return 'Memo';
      case StockStatus.hold:
        return 'Hold';
    }
  }

  static _StatusStyle _statusStyle(StockStatus status) {
    switch (status) {
      case StockStatus.available:
        return const _StatusStyle(
          'Available',
          Color(0xFF269B5B),
        );
      case StockStatus.memo:
        return const _StatusStyle(
          'Memo',
          Color(0xFFEF9B32),
        );
      case StockStatus.hold:
        return const _StatusStyle(
          'Hold',
          Color(0xFF9652D4),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Status Style
// ---------------------------------------------------------------------------

class _StatusStyle {
  final String label;
  final Color color;

  const _StatusStyle(this.label, this.color);
}

// ---------------------------------------------------------------------------
// Summary Item
// ---------------------------------------------------------------------------

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: FontFamily.montserratBold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        FittedBox(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF68738A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}


// ---------------------------------------------------------------------------
// Stock Card
// ---------------------------------------------------------------------------

class _StockCard extends StatelessWidget {
  final StockItem item;
  final VoidCallback? onTap;

  const _StockCard({
    required this.item,
    this.onTap,
  });

  static const Color _navy = Color(0xFF14233E);
  static const Color _blue = Color(0xFF1F6FEB);
  static const Color _border = Color(0xFFE8EBF2);

  @override
  Widget build(BuildContext context) {
    final status = _getStatusStyle(item.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: [
                      // Grid content
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // TOP ROW
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
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
                                    child: _stoneInfoCell('SHAPE', item.shape),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _stoneInfoCell('CARAT', item.carat),
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
                              padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _stoneInfoCell('COLOR', item.color),
                                  ),
                                  Expanded(
                                    child: _stoneInfoCell(
                                        'CLARITY', item.clarity),
                                  ),
                                  Expanded(
                                    child: _stoneInfoCell('CUT', item.cut),
                                  ),
                                ],
                              ),
                            ),

                            _stoneDivider(),

                            // THIRD ROW
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
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

                      // RIGHT ARROW (card detail kholne ke liye)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 26,
                          color: Color(0xFF858EA2),
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
                  child: Container(color: const Color(0xFFF2C51D)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stoneInfoCell(
      String label,
      dynamic value, {
        Color? valueColor,
        double valueSize = 11,
      }) {
    final displayValue = value == null || value.toString().trim().isEmpty
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
            fontWeight: FontWeight.w500,
            color: Color(0xFF9299A8),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          displayValue,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.w500,
            color: valueColor ?? _navy,
          ),
        ),
      ],
    );
  }

  Widget _stoneDivider() => Container(height: 0.7, color: _border);

  static _StatusStyle _getStatusStyle(StockStatus status) {
    switch (status) {
      case StockStatus.available:
        return const _StatusStyle('Available', Color(0xFF269B5B));
      case StockStatus.memo:
        return const _StatusStyle('Memo', Color(0xFFEF9B32));
      case StockStatus.hold:
        return const _StatusStyle('Hold', Color(0xFF9652D4));
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Bottom Actions
// ---------------------------------------------------------------------------

class _BottomActions extends StatelessWidget {
  final VoidCallback? onShare;
  final VoidCallback? onExport;

  const _BottomActions({
    this.onShare,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.ios_share_rounded,
              label: 'Share',
              filled: false,
              onTap: onShare,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              icon: Icons.grid_on_rounded,
              label: 'Export Excel',
              filled: true,
              onTap: onExport,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF269B5B);

    final foreground = filled
        ? Colors.white
        : const Color(0xFF14233E);

    return Material(
      color: filled ? green : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: filled ? green : const Color(0xFFE3E6EF),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: foreground,
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
