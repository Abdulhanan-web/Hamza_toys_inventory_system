// models/product.dart
class Product {
  final int? id;
  final int userId;
  final String productId;
  final String name;
  final String description;
  final int totalPieces; // Unit of inventory
  final int quantityPerBox;
  final double purchasePrice;
  final String arrivalDate;

  Product({
    this.id,
    required this.userId,
    required this.productId,
    required this.name,
    required this.description,
    required this.totalPieces,
    required this.quantityPerBox,
    required this.purchasePrice,
    required this.arrivalDate,
  });

  // Updated getters to handle cases where quantityPerBox is not defined (0)
  int get fullBoxes => (quantityPerBox > 0) ? (totalPieces ~/ quantityPerBox) : 0;
  int get loosePieces => (quantityPerBox > 0) ? (totalPieces % quantityPerBox) : totalPieces;

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "productId": productId,
      "name": name,
      "description": description,
      "totalPieces": totalPieces,
      "quantityPerBox": quantityPerBox,
      "purchasePrice": purchasePrice,
      "arrivalDate": arrivalDate,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map["id"],
      userId: map["userId"] ?? 0,
      productId: map["productId"],
      name: map["name"],
      description: map["description"],
      totalPieces: map["totalPieces"] ?? (map["boxes"] ?? 0) * (map["quantityPerBox"] ?? 1),
      quantityPerBox: map["quantityPerBox"] ?? 0, // Default to 0 if not specified
      purchasePrice: (map["purchasePrice"] as num).toDouble(),
      arrivalDate: map["arrivalDate"],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}