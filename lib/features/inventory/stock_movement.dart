class StockMovement {
  final String id;
  final String businessId;
  final String inventoryItemId;
  final String movementType;
  final double quantity;
  final String? notes;
  final String? referenceId;
  final String? createdBy;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.businessId,
    required this.inventoryItemId,
    required this.movementType,
    required this.quantity,
    this.notes,
    this.referenceId,
    this.createdBy,
    required this.createdAt,
  });

  bool get isIncoming => quantity > 0;
  bool get isOutgoing => quantity < 0;

  String get typeLabel {
    switch (movementType) {
      case 'initial':
        return 'Stok Awal';
      case 'purchase':
        return 'Pembelian';
      case 'usage':
        return 'Pemakaian';
      case 'waste':
        return 'Rusak/Basi';
      case 'adjustment':
        return 'Penyesuaian';
      case 'return':
        return 'Retur';
      default:
        return movementType;
    }
  }

  factory StockMovement.fromMap(Map<String, dynamic> m) => StockMovement(
        id: m['id'] as String,
        businessId: m['business_id'] as String,
        inventoryItemId: m['inventory_item_id'] as String,
        movementType: m['movement_type'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        notes: m['notes'] as String?,
        referenceId: m['reference_id'] as String?,
        createdBy: m['created_by'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
