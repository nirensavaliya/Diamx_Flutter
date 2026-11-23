import 'package:flutter/material.dart';

import '../../../utills/app_colors.dart';
import '../../../utills/app_font.dart';

// Adjust this path to where your CommonScaffold file lives.
import '../dashboard/CommonScaffold.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------
class ReportType {
  final String title;
  final IconData icon;
  final Color color;

  const ReportType({
    required this.title,
    required this.icon,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _reports = <ReportType>[
    ReportType(
      title: 'Stock Report',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF2F7DE1),
    ),
    ReportType(
      title: 'Sales Report',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF2F7DE1),
    ),
    ReportType(
      title: 'Memo Report',
      icon: Icons.description_rounded,
      color: Color(0xFF2F7DE1),
    ),
    ReportType(
      title: 'Hold Report',
      icon: Icons.hourglass_bottom_rounded,
      color: Color(0xFFE8833A),
    ),
    ReportType(
      title: 'Client Summary',
      icon: Icons.groups_rounded,
      color: Color(0xFF2F7DE1),
    ),
    ReportType(
      title: 'Stone-wise Report',
      icon: Icons.diamond_outlined,
      color: Color(0xFF1FA6C9),
    ),
  ];

  // Dummy clients. Replace with your API / provider list.
  static const _clients = ['All Clients','Client A', 'Client B'];

  int _selectedReport = 0;
  String _selectedClient = _clients.first;
  DateTimeRange _range = DateTimeRange(
    start: DateTime(2026, 11, 1),
    end: DateTime(2026, 11, 30),
  );

  String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  void _onGenerate() {
    // call your report API with:
    // _reports[_selectedReport].title, _range, _selectedClient
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: 'Reports',
      showBack: false,
      body: Container(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
          children: [
            _buildReportGrid(),
            const SizedBox(height: 20),
            _buildLabel('Date Range'),
            const SizedBox(height: 8),
            _buildDateField(),
            const SizedBox(height: 16),
            _buildLabel('Client'),
            const SizedBox(height: 8),
            _buildClientDropdown(),
            const SizedBox(height: 22),
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  // ---- Report type grid (2 x 3) ------------------------------------------
  Widget _buildReportGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reports.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      padding: EdgeInsets.zero,

      itemBuilder: (context, i) {
        return _ReportCard(
          report: _reports[i],
          selected: _selectedReport == i,
          onTap: () => setState(() => _selectedReport = i),
        );
      },
    );
  }

  // ---- Field label --------------------------------------------------------
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: FontFamily.montserratBold,
        fontSize: 14,
        color: AppColors.primaryDark,
      ),
    );
  }

  // ---- Date range field ---------------------------------------------------
  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickRange,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: _fieldDecoration(),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 19,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_fmt(_range.start)} - ${_fmt(_range.end)}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: AppColors.primaryDark,
            ),
          ],
        ),
      ),
    );
  }

  // ---- Client dropdown ----------------------------------------------------
  Widget _buildClientDropdown() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _fieldDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedClient,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 22,
            color: AppColors.primaryDark,
          ),
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
          items: [
            for (final c in _clients)
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _selectedClient = value);
          },
        ),
      ),
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE3E6EF)),
    );
  }

  // ---- Generate button ----------------------------------------------------
  Widget _buildGenerateButton() {
    return GestureDetector(
      onTap: _onGenerate,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Generate Report',
          style: TextStyle(
            fontFamily: FontFamily.montserratBold,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Report type card
// ---------------------------------------------------------------------------
class _ReportCard extends StatelessWidget {
  final ReportType report;
  final bool selected;
  final VoidCallback? onTap;

  const _ReportCard({required this.report, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.secondary.withValues(alpha: 0.85),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: report.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(report.icon, size: 26, color: report.color),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                report.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  fontSize: 13,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
