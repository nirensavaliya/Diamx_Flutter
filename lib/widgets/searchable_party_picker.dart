import 'package:flutter/material.dart';

import '../models/party.dart';
import '../utills/app_colors.dart';
import '../utills/app_font.dart';

/// Shared party field with searchable bottom sheet (memo + invoice).
class SearchablePartyPicker extends StatelessWidget {
  const SearchablePartyPicker({
    super.key,
    required this.parties,
    required this.selectedParty,
    required this.isLoading,
    required this.onChanged,
    this.errorText,
    this.hintText = 'Party',
  });

  final List<Party> parties;
  final Party? selectedParty;
  final bool isLoading;
  final String? errorText;
  final String hintText;
  final ValueChanged<Party?> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = selectedParty?.displayName;
    final hasError = errorText != null && errorText!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: isLoading
            ? null
            : () async {
                final result = await showModalBottomSheet<_PartyPickResult>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => _PartySearchSheet(
                    parties: parties,
                    selectedParty: selectedParty,
                  ),
                );
                if (result == null) return;
                onChanged(result.clear ? null : result.party);
              },
        child: InputDecorator(
          isEmpty: label == null || label.isEmpty,
          decoration: InputDecoration(
            hintText: isLoading ? 'Loading...' : hintText,
            errorText: hasError ? errorText : null,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide(
                color: AppColors.secondary.withValues(alpha: 0.8),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            suffixIcon: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
          ),
          // Empty → only decoration hintText. Avoid duplicating hint in child.
          child: Text(
            label == null || label.isEmpty ? '' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: FontFamily.montserratMedium,
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PartyPickResult {
  const _PartyPickResult.party(this.party) : clear = false;
  const _PartyPickResult.clear() : party = null, clear = true;

  final Party? party;
  final bool clear;
}

class _PartySearchSheet extends StatefulWidget {
  const _PartySearchSheet({
    required this.parties,
    required this.selectedParty,
  });

  final List<Party> parties;
  final Party? selectedParty;

  @override
  State<_PartySearchSheet> createState() => _PartySearchSheetState();
}

class _PartySearchSheetState extends State<_PartySearchSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Party> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.parties;
    return widget.parties.where((party) {
      final name = party.displayName.toLowerCase();
      final short = party.shortName.toLowerCase();
      return name.contains(q) || short.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final maxSheet = (media.size.height * 0.72).clamp(360.0, 560.0);
    final sheetHeight = keyboard > 0
        ? (media.size.height - keyboard - media.padding.top - 8)
            .clamp(280.0, maxSheet)
        : maxSheet;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: sheetHeight,
            width: double.infinity,
            child: Column(
              children: [
                ColoredBox(
                  color: AppColors.primaryDark,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Party',
                                style: TextStyle(
                                  fontFamily: FontFamily.montserratBold,
                                  color: AppColors.white,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${filtered.length} of ${widget.parties.length} parties',
                                style: TextStyle(
                                  fontFamily: FontFamily.montserratRegular,
                                  color:
                                      AppColors.white.withValues(alpha: 0.72),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: TextField(
                    controller: _controller,
                    autofocus: false,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => setState(() => _query = value),
                    style: TextStyle(
                      fontFamily: FontFamily.montserratMedium,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search party name...',
                      hintStyle: TextStyle(
                        fontFamily: FontFamily.montserratRegular,
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _controller.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.secondary.withValues(alpha: 0.85),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Material(
                    color: widget.selectedParty == null
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(
                        context,
                        const _PartyPickResult.clear(),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.groups_rounded,
                              size: 18,
                              color: widget.selectedParty == null
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'All Parties',
                                style: TextStyle(
                                  fontFamily: FontFamily.montserratSemiBold,
                                  fontSize: 12.5,
                                  color: widget.selectedParty == null
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (widget.selectedParty == null)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Divider(
                    height: 1,
                    color: AppColors.secondary.withValues(alpha: 0.85),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            widget.parties.isEmpty
                                ? 'No parties loaded'
                                : 'No party match',
                            style: TextStyle(
                              fontFamily: FontFamily.montserratMedium,
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemBuilder: (context, index) {
                            final party = filtered[index];
                            final isSelected =
                                widget.selectedParty?.ledgerId ==
                                    party.ledgerId;
                            return Material(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.07)
                                  : Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pop(
                                  context,
                                  _PartyPickResult.party(party),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            party.displayName.isNotEmpty
                                                ? party.displayName[0]
                                                    .toUpperCase()
                                                : 'P',
                                            style: TextStyle(
                                              fontFamily:
                                                  FontFamily.montserratBold,
                                              color: AppColors.primary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              party.displayName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: isSelected
                                                    ? FontFamily
                                                        .montserratSemiBold
                                                    : FontFamily
                                                        .montserratMedium,
                                                fontSize: 12.5,
                                                color: isSelected
                                                    ? AppColors.primaryDark
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                            if (party.shortName
                                                    .trim()
                                                    .isNotEmpty &&
                                                party.shortName
                                                        .trim()
                                                        .toLowerCase() !=
                                                    party.displayName
                                                        .toLowerCase()) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                party.shortName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: FontFamily
                                                      .montserratRegular,
                                                  fontSize: 10,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
