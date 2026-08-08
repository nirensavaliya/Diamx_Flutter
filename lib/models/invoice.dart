enum InvoiceStatus { pending, paid }

class InvoiceItem {
  const InvoiceItem({
    required this.id,
    required this.stockNumber,
    required this.shape,
    required this.carat,
    required this.color,
    required this.clarity,
    required this.pricePerCarat,
    required this.total,
  });

  final String id;
  final String stockNumber;
  final String shape;
  final double carat;
  final String color;
  final String clarity;
  final double pricePerCarat;
  final double total;
}

class Invoice {
  const Invoice({
    required this.id,
    required this.title,
    required this.description,
    required this.customerName,
    required this.date,
    required this.dueDate,
    required this.status,
    required this.taxRate,
    required this.items,
  });

  final String id;
  final String title;
  final String description;
  final String customerName;
  final DateTime date;
  final DateTime dueDate;
  final InvoiceStatus status;
  final double taxRate;
  final List<InvoiceItem> items;

  double get subtotal => items.fold<double>(0, (sum, item) => sum + item.total);
  double get taxAmount => subtotal * taxRate / 100;
  double get grandTotal => subtotal + taxAmount;

  String get statusLabel => switch (status) {
    InvoiceStatus.pending => 'Pending',
    InvoiceStatus.paid => 'Paid',
  };
}
