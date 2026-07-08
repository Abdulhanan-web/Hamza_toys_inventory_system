class Client {
  final int? id;
  final String clientId;
  final String name;
  final String phone;
  final String address;
  final String createdAt;

  Client({
    this.id,
    required this.clientId,
    required this.name,
    required this.phone,
    required this.address,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "clientId": clientId,
      "name": name,
      "phone": phone,
      "address": address,
      "createdAt": createdAt,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map["id"] as int?,
      clientId: map["clientId"] ?? "",
      name: map["name"] ?? "",
      phone: map["phone"] ?? "",
      address: map["address"] ?? "",
      createdAt: map["createdAt"] ?? "",
    );
  }

  Client copyWith({
    int? id,
    String? clientId,
    String? name,
    String? phone,
    String? address,
    String? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}