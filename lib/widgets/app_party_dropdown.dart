import 'package:flutter/material.dart';

import '../models/party.dart';
import '../providers/memo_provider.dart';
import '../utills/app_colors.dart';
import '../utills/app_font.dart';

class PartyDropdown extends StatelessWidget {
  const PartyDropdown({required this.provider});

  final MemoProvider provider;

  @override
  Widget build(BuildContext context) {
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
      child: DropdownButtonFormField<Party>(
        key: ValueKey(
          '${provider.parties.length}-${provider.selectedParty?.ledgerId}',
        ),
        initialValue: provider.selectedParty,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.primary,
          size: 20,
        ),
        decoration: InputDecoration(
          hintText: provider.isPartiesLoading ? 'Loading...' : 'Party',
          errorText: provider.partiesError,
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
        ),
        items: provider.parties
            .map(
              (party) => DropdownMenuItem<Party>(
            value: party,
            child: Text(
              party.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: FontFamily.montserratMedium,
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        )
            .toList(),
        onChanged: provider.isPartiesLoading
            ? null
            : (party) {
                provider.selectParty(party);
              },
      ),
    );
  }
}