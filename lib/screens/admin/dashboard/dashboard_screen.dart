import 'package:diamax_flutter/utills/app_images.dart';
import 'package:diamax_flutter/utills/app_colors.dart';
import 'package:diamax_flutter/utills/app_font.dart';
import 'package:flutter/material.dart';

import 'CommonScaffold.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onViewAllTransactions;

  const DashboardScreen({super.key, this.onViewAllTransactions});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedClient = 'All Clients';

  final Color blue = AppColors.primary;
  final Color orange = AppColors.accentDark;
  final Color green = AppColors.success;
  final Color red = const Color(0xFFE65B54);
  final Color purple = AppColors.primaryLight;

  static const double _dropdownHeight = 52;
  Color get _textPrimary => AppColors.textPrimary;

  Color get _textSecondary => AppColors.textSecondary;

  Color get _borderColor => AppColors.secondary.withValues(alpha: 0.85);

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: 'Dashboard',
      actions: [AppBarAction.notification(count: 3, onTap: () {})],
      body: Stack(
        children: [
          Container(
            color: AppColors.background,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: _buildClientDropdown(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 115),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeading(
                          'Overview',
                          'Your business performance at a glance',
                        ),
                        const SizedBox(height: 14),
                        _buildSummaryCards(),
                        const SizedBox(height: 26),
                        _buildSalesChart(),
                        const SizedBox(height: 20),
                        _buildRecentTransactions(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SECTION HEADING

  Widget _buildSectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: FontFamily.montserratBold,
            color: _textPrimary,
            fontSize: 18,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: FontFamily.montserratRegular,
            color: _textSecondary,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  // COMMON CARD DECORATION

  BoxDecoration _cardDecoration({double radius = 20}) {
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

  // CLIENT DROPDOWN

  Widget _buildClientDropdown() {
    return Container(
      height: _dropdownHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _cardDecoration(radius: 16),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.people_alt_outlined, color: blue, size: 19),
          ),
          const SizedBox(width: 11),
          Text(
            'Client',
            style: TextStyle(
              fontFamily: FontFamily.montserratMedium,
              color: _textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedClient,
                isExpanded: true,
                borderRadius: BorderRadius.circular(14),
                alignment: Alignment.centerRight,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _textSecondary,
                  size: 22,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'All Clients',
                    child: Text('All Clients'),
                  ),
                  DropdownMenuItem(value: 'Client A', child: Text('Client A')),
                  DropdownMenuItem(value: 'Client B', child: Text('Client B')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedClient = value);
                  }
                },
                style: TextStyle(
                  fontFamily: FontFamily.montserratSemiBold,
                  color: _textPrimary,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SUMMARY CARDS

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.20,
      padding: EdgeInsets.zero,
      children: [
        _summaryCard(
          title: 'Polish Diamond',
          value: '5,250',
          change: '+2.5%',
          assetIcon: AppImages.polishDiamond,
          iconColor: blue,
          positive: true,
        ),
        _summaryCard(
          title: 'Jewellery',
          value: '1,480',
          change: '+1.2%',
          assetIcon: AppImages.jewellery,
          iconColor: orange,
          positive: true,
        ),
        _summaryCard(
          title: 'Loose Diamond',
          value: '3,120',
          change: '-0.8%',
          assetIcon: AppImages.looseDiamond,
          iconColor: purple,
          positive: false,
        ),
        _summaryCard(
          title: 'Total Sales',
          value: '8,980',
          change: '+3.1%',
          assetIcon: AppImages.totalSales,
          iconColor: green,
          positive: true,
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String change,
    String? assetIcon,
    IconData? icon,
    required Color iconColor,
    required bool positive,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: assetIcon != null
                    ? Image.asset(
                        assetIcon,
                        fit: BoxFit.contain,
                        color: iconColor,
                        colorBlendMode: BlendMode.srcIn,
                      )
                    : Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: (positive ? green : red).withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  positive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 16,
                  color: positive ? green : red,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: FontFamily.montserratMedium,
              color: _textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: FontFamily.montserratExtraBold,
                color: _textPrimary,
                fontSize: 21,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            change,
            style: TextStyle(
              fontFamily: FontFamily.montserratBold,
              color: positive ? green : red,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // SALES CHART

  Widget _buildSalesChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 13),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Trend',
                      style: TextStyle(
                        fontFamily: FontFamily.montserratBold,
                        color: _textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Performance over the last 7 days',
                      style: TextStyle(
                        fontFamily: FontFamily.montserratRegular,
                        color: _textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              _legend(blue, 'Sales'),
              const SizedBox(width: 12),
              _legend(orange, 'Memo'),
            ],
          ),
          const SizedBox(height: 21),
          SizedBox(
            height: 155,
            width: double.infinity,
            child: CustomPaint(
              painter: SalesChartPainter(salesColor: blue, memoColor: orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          title,
          style: TextStyle(
            fontFamily: FontFamily.montserratSemiBold,
            color: _textSecondary,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // RECENT TRANSACTIONS

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Transactions',
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  color: _textPrimary,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                widget.onViewAllTransactions?.call();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View All',
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  color: blue,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
          decoration: _cardDecoration(radius: 19),
          child: Column(
            children: [
              _transactionRow(
                icon: Icons.diamond_outlined,
                iconColor: blue,
                type: 'Sale',
                code: 'PS/1473',
                date: '30/11/2026',
                amount: '₹2,45,000',
              ),
              _transactionDivider(),
              _transactionRow(
                icon: Icons.description_outlined,
                iconColor: purple,
                type: 'Memo',
                code: 'M/954',
                date: '30/11/2026',
                amount: '₹85,000',
              ),
              _transactionDivider(),
              _transactionRow(
                icon: Icons.hourglass_bottom_rounded,
                iconColor: orange,
                type: 'Hold',
                code: 'H/203',
                date: '30/11/2026',
                amount: '₹1,20,000',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _transactionDivider() {
    return Divider(height: 1, thickness: 0.8, color: _borderColor);
  }

  Widget _transactionRow({
    required IconData icon,
    required Color iconColor,
    required String type,
    required String code,
    required String date,
    required String amount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    fontFamily: FontFamily.montserratBold,
                    color: iconColor,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: TextStyle(
                    fontFamily: FontFamily.montserratSemiBold,
                    color: _textPrimary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: TextStyle(
                    fontFamily: FontFamily.montserratRegular,
                    color: _textSecondary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            amount,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: FontFamily.montserratBold,
              color: _textPrimary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// CUSTOM SALES CHART

class SalesChartPainter extends CustomPainter {
  final Color salesColor;
  final Color memoColor;

  SalesChartPainter({required this.salesColor, required this.memoColor});

  final List<double> sales = [1.2, 1.7, 2.0, 2.3, 2.1, 2.3, 2.6];
  final List<double> memo = [0.6, 0.9, 1.2, 1.1, 1.0, 1.3, 1.6];

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0;
    const right = 10.0;
    const top = 8.0;
    const bottom = 23.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    final gridPaint = Paint()
      ..color = const Color(0xFFE9EDF3)
      ..strokeWidth = 0.9;

    final axisPaint = Paint()
      ..color = const Color(0xFFD4DCE7)
      ..strokeWidth = 1;

    const labelStyle = TextStyle(
      color: Color(0xFF8995A8),
      fontSize: 9,
      fontWeight: FontWeight.w600,
    );

    for (int i = 0; i <= 3; i++) {
      final y = top + chartHeight * i / 3;

      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );

      _drawText(
        canvas,
        ['3k', '2k', '1k', '0'][i],
        Offset(0, y - 5),
        labelStyle,
      );
    }

    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + chartHeight),
      axisPaint,
    );

    canvas.drawLine(
      Offset(left, top + chartHeight),
      Offset(size.width - right, top + chartHeight),
      axisPaint,
    );

    final dates = ['24', '25', '26', '27', '28', '29', '30'];

    for (int i = 0; i < dates.length; i++) {
      final x = left + chartWidth * i / (dates.length - 1);

      final textPainter = TextPainter(
        text: TextSpan(text: dates[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 14),
      );
    }

    _drawLine(canvas, sales, salesColor, left, top, chartWidth, chartHeight);

    _drawLine(canvas, memo, memoColor, left, top, chartWidth, chartHeight);
  }

  void _drawLine(
    Canvas canvas,
    List<double> values,
    Color color,
    double left,
    double top,
    double width,
    double height,
  ) {
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = left + width * i / (values.length - 1);
      final y = top + height - (values[i] / 3) * height;

      final point = Offset(x, y);
      points.add(point);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(point, 2.2, innerPaint);
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant SalesChartPainter oldDelegate) {
    return oldDelegate.salesColor != salesColor ||
        oldDelegate.memoColor != memoColor;
  }
}
