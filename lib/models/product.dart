class Product {
  final int? id;
  final String productId;
  final String name;
  final String description;
  final int boxes;
  final int quantityPerBox;
  final double purchasePrice;
  final String arrivalDate;

  Product({
    this.id,
    required this.productId,
    required this.name,
    required this.description,
    required this.boxes,
    required this.quantityPerBox,
    required this.purchasePrice,
    required this.arrivalDate,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "productId": productId,
      "name": name,
      "description": description,
      "boxes": boxes,
      "quantityPerBox": quantityPerBox,
      "purchasePrice": purchasePrice,
      "arrivalDate": arrivalDate,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map["id"],
      productId: map["productId"],
      name: map["name"],
      description: map["description"],
      boxes: map["boxes"],
      quantityPerBox: map["quantityPerBox"],
      purchasePrice: map["purchasePrice"],
      arrivalDate: map["arrivalDate"],
    );
  }
}