class Batch {
  final int? id;
  final int productId;
  final int quantityPurchased;
  final int quantityRemaining;
  final double purchasePrice;
  final String purchaseDate;

  Batch({
    this.id,
    required this.productId,
    required this.quantityPurchased,
    required this.quantityRemaining,
    required this.purchasePrice,
    required this.purchaseDate,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "productId": productId,
      "quantityPurchased": quantityPurchased,
      "quantityRemaining": quantityRemaining,
      "purchasePrice": purchasePrice,
      "purchaseDate": purchaseDate,
    };
  }

  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map["id"],
      productId: map["productId"],
      quantityPurchased: map["quantityPurchased"],
      quantityRemaining: map["quantityRemaining"],
      purchasePrice: (map["purchasePrice"] as num).toDouble(),
      purchaseDate: map["purchaseDate"],
    );
  }
}
