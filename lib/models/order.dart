// models/order.dart
class Order {
  final int? id;
  final int userId;
  final String orderNo;
  final int clientId;
  final String orderDate;
  final double totalAmount; // Total before discount
  final double discount;
  final double grandTotal; // Total after discount
  final double previousBalance; // Client balance BEFORE this order
  final double paidAmount;
  final double remainingAmount;
  final String status;
  final String remarks;

  Order({
    this.id,
    required this.userId,
    required this.orderNo,
    required this.clientId,
    required this.orderDate,
    required this.totalAmount,
    required this.discount,
    required this.grandTotal,
    required this.previousBalance,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    required this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "orderNo": orderNo,
      "clientId": clientId,
      "orderDate": orderDate,
      "totalAmount": totalAmount,
      "discount": discount,
      "grandTotal": grandTotal,
      "previousBalance": previousBalance,
      "paidAmount": paidAmount,
      "remainingAmount": remainingAmount,
      "status": status,
      "remarks": remarks,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map["id"],
      userId: map["userId"] ?? 0,
      orderNo: map["orderNo"],
      clientId: map["clientId"],
      orderDate: map["orderDate"],
      totalAmount: (map["totalAmount"] as num?)?.toDouble() ?? (map["grandTotal"] as num).toDouble(),
      discount: (map["discount"] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map["grandTotal"] as num).toDouble(),
      previousBalance: (map["previousBalance"] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map["paidAmount"] as num).toDouble(),
      remainingAmount: (map["remainingAmount"] as num).toDouble(),
      status: map["status"],
      remarks: map["remarks"],
    );
  }

  Order copyWith({
    int? id,
    int? userId,
    String? orderNo,
    int? clientId,
    String? orderDate,
    double? totalAmount,
    double? discount,
    double? grandTotal,
    double? previousBalance,
    double? paidAmount,
    double? remainingAmount,
    String? status,
    String? remarks,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderNo: orderNo ?? this.orderNo,
      clientId: clientId ?? this.clientId,
      orderDate: orderDate ?? this.orderDate,
      totalAmount: totalAmount ?? this.totalAmount,
      discount: discount ?? this.discount,
      grandTotal: grandTotal ?? this.grandTotal,
      previousBalance: previousBalance ?? this.previousBalance,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
    );
  }
}
