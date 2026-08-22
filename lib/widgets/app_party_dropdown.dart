import 'package:flutter/material.dart';

import '../providers/memo_provider.dart';
import 'searchable_party_picker.dart';

class PartyDropdown extends StatelessWidget {
  const PartyDropdown({super.key, required this.provider});

  final MemoProvider provider;

  @override
  Widget build(BuildContext context) {
    return SearchablePartyPicker(
      parties: provider.parties,
      selectedParty: provider.selectedParty,
      isLoading: provider.isPartiesLoading,
      errorText: provider.partiesError,
      hintText: 'Party',
      onChanged: provider.selectParty,
    );
  }
}
