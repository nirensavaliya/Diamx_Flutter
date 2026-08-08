import 'package:flutter/material.dart';

import '../models/invoice.dart';

class InvoiceProvider extends ChangeNotifier {
  InvoiceProvider() {
    searchController.addListener(_filterInvoices);
  }

  final TextEditingController searchController = TextEditingController();
  final List<Invoice> _invoices = _demoInvoices;
  List<Invoice> _filteredInvoices = _demoInvoices;

  List<Invoice> get invoices => List.unmodifiable(_filteredInvoices);
  int get totalInvoices => _invoices.length;
  int get pendingInvoices => _invoices
      .where((invoice) => invoice.status == InvoiceStatus.pending)
      .length;
  int get paidInvoices =>
      _invoices.where((invoice) => invoice.status == InvoiceStatus.paid).length;

  void _filterInvoices() {
    final query = searchController.text.trim().toLowerCase();
    _filteredInvoices = query.isEmpty
        ? _invoices
        : _invoices.where((invoice) {
            return invoice.title.toLowerCase().contains(query) ||
                invoice.id.toLowerCase().contains(query) ||
                invoice.customerName.toLowerCase().contains(query);
          }).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    searchController
      ..removeListener(_filterInvoices)
      ..dispose();
    super.dispose();
  }
}

final List<Invoice> _demoInvoices = [
  Invoice(
    id: 'INV-2001',
    title: 'Round Diamond Invoice',
    description: 'Premium round diamonds supplied against confirmed order.',
    customerName: 'Aarav Jewels',
    date: DateTime(2026, 7, 28),
    dueDate: DateTime(2026, 8, 12),
    status: InvoiceStatus.pending,
    taxRate: 3,
    items: const [
      InvoiceItem(
        id: 'I-101',
        stockNumber: 'STK-2401',
        shape: 'Round',
        carat: 0.62,
        color: 'F',
        clarity: 'VS1',
        pricePerCarat: 4800,
        total: 2976,
      ),
      InvoiceItem(
        id: 'I-102',
        stockNumber: 'STK-2402',
        shape: 'Round',
        carat: 0.58,
        color: 'G',
        clarity: 'VVS2',
        pricePerCarat: 5050,
        total: 2929,
      ),
      InvoiceItem(
        id: 'I-103',
        stockNumber: 'STK-2403',
        shape: 'Round',
        carat: 0.60,
        color: 'F',
        clarity: 'VS2',
        pricePerCarat: 4708.33,
        total: 2825,
      ),
    ],
  ),
  Invoice(
    id: 'INV-2002',
    title: 'Emerald Cut Collection',
    description: 'Emerald cut diamonds delivered for bespoke jewellery.',
    customerName: 'Eternal Gems',
    date: DateTime(2026, 7, 25),
    dueDate: DateTime(2026, 8, 9),
    status: InvoiceStatus.paid,
    taxRate: 3,
    items: const [
      InvoiceItem(
        id: 'I-201',
        stockNumber: 'STK-2511',
        shape: 'Emerald',
        carat: 1.20,
        color: 'E',
        clarity: 'VS1',
        pricePerCarat: 5400,
        total: 6480,
      ),
      InvoiceItem(
        id: 'I-202',
        stockNumber: 'STK-2512',
        shape: 'Emerald',
        carat: 1.20,
        color: 'F',
        clarity: 'VS2',
        pricePerCarat: 5000,
        total: 6000,
      ),
    ],
  ),
  Invoice(
    id: 'INV-2003',
    title: 'Princess Cut Parcel',
    description: 'Matched princess cut parcel for a bridal collection.',
    customerName: 'Royal Ornaments',
    date: DateTime(2026, 7, 22),
    dueDate: DateTime(2026, 8, 6),
    status: InvoiceStatus.pending,
    taxRate: 3,
    items: const [
      InvoiceItem(
        id: 'I-301',
        stockNumber: 'STK-2630',
        shape: 'Princess',
        carat: 0.85,
        color: 'G',
        clarity: 'VS1',
        pricePerCarat: 4200,
        total: 3570,
      ),
      InvoiceItem(
        id: 'I-302',
        stockNumber: 'STK-2631',
        shape: 'Princess',
        carat: 0.85,
        color: 'G',
        clarity: 'VS2',
        pricePerCarat: 4000,
        total: 3400,
      ),
    ],
  ),
  Invoice(
    id: 'INV-2004',
    title: 'Oval Signature Stones',
    description: 'Fine oval diamonds supplied for signature rings.',
    customerName: 'Saanvi Diamonds',
    date: DateTime(2026, 7, 18),
    dueDate: DateTime(2026, 8, 2),
    status: InvoiceStatus.paid,
    taxRate: 3,
    items: const [
      InvoiceItem(
        id: 'I-401',
        stockNumber: 'STK-2701',
        shape: 'Oval',
        carat: 1.05,
        color: 'E',
        clarity: 'VVS2',
        pricePerCarat: 5800,
        total: 6090,
      ),
      InvoiceItem(
        id: 'I-402',
        stockNumber: 'STK-2702',
        shape: 'Oval',
        carat: 0.95,
        color: 'F',
        clarity: 'VS1',
        pricePerCarat: 5484.21,
        total: 5210,
      ),
    ],
  ),
];
