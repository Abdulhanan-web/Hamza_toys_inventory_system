// models/order_item.dart
class OrderItem {
  final int? id;
  final int orderId;
  final int productId;

  // Values for this specific order
  final int boxes;
  final int loosePieces;
  final int quantityPerBox;
  final double sellingPrice;

  // Calculated total for this item
  final double totalPrice;
  final double discount;
  final double costPrice; // For FIFO profit tracking

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.boxes,
    this.loosePieces = 0,
    required this.quantityPerBox,
    required this.sellingPrice,
    required this.totalPrice,
    required this.discount,
    this.costPrice = 0.0,
  });

  int get totalPieces => (boxes * quantityPerBox) + loosePieces;

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "orderId": orderId,
      "productId": productId,
      "boxes": boxes,
      "loosePieces": loosePieces,
      "quantityPerBox": quantityPerBox,
      "sellingPrice": sellingPrice,
      "totalPrice": totalPrice,
      "discount": discount,
      "costPrice": costPrice,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map["id"],
      orderId: map["orderId"] ?? 0,
      productId: map["productId"] ?? 0,
      boxes: map["boxes"] ?? 0,
      loosePieces: map["loosePieces"] ?? 0,
      quantityPerBox: map["quantityPerBox"] ?? 1,
      sellingPrice: (map["sellingPrice"] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map["totalPrice"] as num?)?.toDouble() ?? 0.0,
      discount: (map["discount"] as num?)?.toDouble() ?? 0.0,
      costPrice: (map["costPrice"] as num?)?.toDouble() ?? 0.0,
    );
  }

  OrderItem copyWith({
    int? id,
    int? orderId,
    int? productId,
    int? boxes,
    int? loosePieces,
    int? quantityPerBox,
    double? sellingPrice,
    double? totalPrice,
    double? discount,
    double? costPrice,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      boxes: boxes ?? this.boxes,
      loosePieces: loosePieces ?? this.loosePieces,
      quantityPerBox: quantityPerBox ?? this.quantityPerBox,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      discount: discount ?? this.discount,
      costPrice: costPrice ?? this.costPrice,
    );
  }
}
