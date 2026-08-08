import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/invoice.dart';
import '../services/pdf_service.dart';

class InvoicePrintProvider extends ChangeNotifier {
  InvoicePrintProvider(this.invoice, {this.pdfService = const PdfService()});

  final Invoice invoice;
  final PdfService pdfService;
  final Set<String> _selectedItemIds = {};

  Uint8List? _signature;
  bool _isGenerating = false;
  String? _lastSavedPath;
  String? _errorMessage;

  Set<String> get selectedItemIds => Set.unmodifiable(_selectedItemIds);
  Uint8List? get signature => _signature;
  bool get hasSignature => _signature != null;
  bool get isGenerating => _isGenerating;
  bool get isAllSelected =>
      _selectedItemIds.length == invoice.items.length &&
      invoice.items.isNotEmpty;
  String? get lastSavedPath => _lastSavedPath;
  String? get errorMessage => _errorMessage;

  void toggleItem(String itemId) {
    if (!_selectedItemIds.add(itemId)) {
      _selectedItemIds.remove(itemId);
    }
    _errorMessage = null;
    notifyListeners();
  }

  void toggleSelectAll() {
    if (isAllSelected) {
      _selectedItemIds.clear();
    } else {
      _selectedItemIds
        ..clear()
        ..addAll(invoice.items.map((item) => item.id));
    }
    _errorMessage = null;
    notifyListeners();
  }

  void setSignature(Uint8List signature) {
    _signature = signature;
    notifyListeners();
  }

  void clearSignature() {
    _signature = null;
    notifyListeners();
  }

  Future<bool> generatePdf({Rect? sharePositionOrigin}) async {
    if (_selectedItemIds.isEmpty) {
      _errorMessage = 'Select at least one diamond';
      notifyListeners();
      return false;
    }

    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final selectedItems = invoice.items
          .where((item) => _selectedItemIds.contains(item.id))
          .toList();
      _lastSavedPath = await pdfService.generateAndShareInvoice(
        invoice: invoice,
        items: selectedItems,
        signature: _signature,
        sharePositionOrigin: sharePositionOrigin,
      );
      return true;
    } catch (error) {
      debugPrint('INVOICE PDF ERROR: $error');
      _errorMessage = 'Unable to generate PDF. Please try again.';
      return false;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
}
