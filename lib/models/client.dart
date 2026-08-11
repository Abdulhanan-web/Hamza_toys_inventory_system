// models/client.dart
class Client {
  final int? id;
  final int userId;
  final String clientId;
  final String name;
  final String phone;
  final String address;
  final double balance;
  final String notes;
  final String createdAt;

  Client({
    this.id,
    required this.userId,
    required this.clientId,
    required this.name,
    required this.phone,
    required this.address,
    required this.balance,
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "clientId": clientId,
      "name": name,
      "phone": phone,
      "address": address,
      "balance": balance,
      "notes": notes,
      "createdAt": createdAt,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map["id"] as int?,
      userId: map["userId"] ?? 0,
      clientId: map["clientId"] ?? "",
      name: map["name"] ?? "",
      phone: map["phone"] ?? "",
      address: map["address"] ?? "",
      balance: (map["balance"] as num).toDouble(),
      notes: map["notes"] ?? "",
      createdAt: map["createdAt"] ?? "",
    );
  }

  Client copyWith({
    int? id,
    int? userId,
    String? clientId,
    String? name,
    String? phone,
    String? address,
    double? balance,
    String? notes,
    String? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}