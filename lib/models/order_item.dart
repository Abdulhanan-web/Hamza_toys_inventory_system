// models/order_item.dart
class OrderItem {
  final int? id;
  final int orderId;
  final int productId;

  // Values for this specific order
  final int boxes;
  final int quantityPerBox;
  final double sellingPrice;

  // Calculated total for this item
  final double totalPrice;
  final double discount;

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.boxes,
    required this.quantityPerBox,
    required this.sellingPrice,
    required this.totalPrice,
    required this.discount,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "orderId": orderId,
      "productId": productId,
      "boxes": boxes,
      "quantityPerBox": quantityPerBox,
      "sellingPrice": sellingPrice,
      "totalPrice": totalPrice,
      "discount": discount,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map["id"],
      orderId: map["orderId"],
      productId: map["productId"],
      boxes: map["boxes"],
      quantityPerBox: map["quantityPerBox"],
      sellingPrice: (map["sellingPrice"] as num).toDouble(),
      totalPrice: (map["totalPrice"] as num).toDouble(),
      discount: (map["discount"] as num).toDouble(),
    );
  }

  OrderItem copyWith({
    int? id,
    int? orderId,
    int? productId,
    int? boxes,
    int? quantityPerBox,
    double? sellingPrice,
    double? totalPrice,
    double? discount,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      boxes: boxes ?? this.boxes,
      quantityPerBox: quantityPerBox ?? this.quantityPerBox,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      discount: discount ?? this.discount,
    );
  }
}