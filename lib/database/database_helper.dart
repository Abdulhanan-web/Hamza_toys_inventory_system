import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user.dart';
import '../models/product.dart';
import '../models/client.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB("inventory.db");
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute("PRAGMA foreign_keys = ON");
      },
    );
  }

  Future<void> _onUpgrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    // Future database upgrades go here.
  }

  Future<void> _createDB(Database db, int version) async {

    //---------------- USERS ----------------//

    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT
      )
    ''');

    //---------------- PRODUCTS ----------------//

    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId TEXT UNIQUE,
        name TEXT,
        description TEXT,
        boxes INTEGER,
        quantityPerBox INTEGER,
        purchasePrice REAL,
        arrivalDate TEXT
      )
    ''');

    //---------------- CLIENTS ----------------//

    await db.execute('''
      CREATE TABLE clients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientCode TEXT UNIQUE,
        name TEXT,
        phone TEXT,
        address TEXT,
        createdDate TEXT
      )
    ''');

    //---------------- ORDERS ----------------//

    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderNo TEXT UNIQUE,
        clientId INTEGER,
        orderDate TEXT,
        grandTotal REAL,
        paidAmount REAL,
        remainingAmount REAL,
        status TEXT,
        remarks TEXT,

        FOREIGN KEY(clientId)
        REFERENCES clients(id)
        ON DELETE CASCADE
      )
    ''');

    //---------------- ORDER ITEMS ----------------//

    await db.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER,
        productId INTEGER,
        boxes INTEGER,
        quantityPerBox INTEGER,
        sellingPrice REAL,
        totalPrice REAL,

        FOREIGN KEY(orderId)
        REFERENCES orders(id)
        ON DELETE CASCADE,

        FOREIGN KEY(productId)
        REFERENCES products(id)
      )
    ''');
  }
  //======================== USERS ========================//

  Future<int> insertUser(User user) async {
    final db = await database;

    return await db.insert(
      "users",
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<User?> login(String username, String password) async {
    final db = await database;

    final result = await db.query(
      "users",
      where: "username=? AND password=?",
      whereArgs: [username, password],
    );

    if (result.isEmpty) return null;

    return User.fromMap(result.first);
  }

  Future<bool> usernameExists(String username) async {
    final db = await database;

    final result = await db.query(
      "users",
      where: "username=?",
      whereArgs: [username],
    );

    return result.isNotEmpty;
  }

  //======================== PRODUCTS ========================//

  Future<int> insertProduct(Product product) async {
    final db = await database;

    return await db.insert(
      "products",
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Product>> getProducts() async {
    final db = await database;

    final result = await db.query(
      "products",
      orderBy: "name ASC",
    );

    return result.map((e) => Product.fromMap(e)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;

    final result = await db.query(
      "products",
      where: "id=?",
      whereArgs: [id],
    );

    if (result.isEmpty) return null;

    return Product.fromMap(result.first);
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;

    return await db.update(
      "products",
      product.toMap(),
      where: "id=?",
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;

    return await db.delete(
      "products",
      where: "id=?",
      whereArgs: [id],
    );
  }

  Future<int> getProductCount() async {
    final db = await database;

    final result =
    await db.rawQuery("SELECT COUNT(*) FROM products");

    return Sqflite.firstIntValue(result) ?? 0;
  }

  //======================== CLIENTS ========================//

  Future<int> insertClient(Client client) async {
    final db = await database;

    return await db.insert(
      "clients",
      client.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Client>> getClients() async {
    final db = await database;

    final result = await db.query(
      "clients",
      orderBy: "name ASC",
    );

    return result.map((e) => Client.fromMap(e)).toList();
  }

  Future<Client?> getClientById(int id) async {
    final db = await database;

    final result = await db.query(
      "clients",
      where: "id=?",
      whereArgs: [id],
    );

    if (result.isEmpty) return null;

    return Client.fromMap(result.first);
  }

  Future<int> updateClient(Client client) async {
    final db = await database;

    return await db.update(
      "clients",
      client.toMap(),
      where: "id=?",
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await database;

    return await db.delete(
      "clients",
      where: "id=?",
      whereArgs: [id],
    );
  }

  Future<int> getClientCount() async {
    final db = await database;

    final result =
    await db.rawQuery("SELECT COUNT(*) FROM clients");

    return Sqflite.firstIntValue(result) ?? 0;
  }
  //======================== ORDERS ========================//

  Future<int> insertOrder(Order order) async {
    final db = await database;

    return await db.insert(
      "orders",
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Order>> getOrders() async {
    final db = await database;

    final result = await db.query(
      "orders",
      orderBy: "orderDate DESC",
    );

    return result.map((e) => Order.fromMap(e)).toList();
  }

  Future<Order?> getOrderById(int id) async {
    final db = await database;

    final result = await db.query(
      "orders",
      where: "id=?",
      whereArgs: [id],
    );

    if (result.isEmpty) return null;

    return Order.fromMap(result.first);
  }

  Future<List<Order>> getOrdersByClient(int clientId) async {
    final db = await database;

    final result = await db.query(
      "orders",
      where: "clientId=?",
      whereArgs: [clientId],
      orderBy: "orderDate DESC",
    );

    return result.map((e) => Order.fromMap(e)).toList();
  }

  Future<int> updateOrder(Order order) async {
    final db = await database;

    return await db.update(
      "orders",
      order.toMap(),
      where: "id=?",
      whereArgs: [order.id],
    );
  }

  Future<int> deleteOrder(int id) async {
    final db = await database;

    return await db.delete(
      "orders",
      where: "id=?",
      whereArgs: [id],
    );
  }

  Future<int> getOrderCount() async {
    final db = await database;

    final result =
    await db.rawQuery("SELECT COUNT(*) FROM orders");

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> getTotalSales() async {
    final db = await database;

    final result = await db.rawQuery(
      "SELECT SUM(grandTotal) FROM orders",
    );

    if (result.first.values.first == null) {
      return 0;
    }

    return (result.first.values.first as num).toDouble();
  }

  Future<double> getTotalRemaining() async {
    final db = await database;

    final result = await db.rawQuery(
      "SELECT SUM(remainingAmount) FROM orders",
    );

    if (result.first.values.first == null) {
      return 0;
    }

    return (result.first.values.first as num).toDouble();
  }

  Future<double> getTotalReceived() async {
    final db = await database;

    final result = await db.rawQuery(
      "SELECT SUM(paidAmount) FROM orders",
    );

    if (result.first.values.first == null) {
      return 0;
    }

    return (result.first.values.first as num).toDouble();
  }
  //======================== ORDER ITEMS ========================//

  Future<int> insertOrderItem(OrderItem item) async {
    final db = await database;

    return await db.insert(
      "order_items",
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final db = await database;

    final result = await db.query(
      "order_items",
      where: "orderId=?",
      whereArgs: [orderId],
    );

    return result.map((e) => OrderItem.fromMap(e)).toList();
  }

  Future<int> updateOrderItem(OrderItem item) async {
    final db = await database;

    return await db.update(
      "order_items",
      item.toMap(),
      where: "id=?",
      whereArgs: [item.id],
    );
  }

  Future<int> deleteOrderItem(int id) async {
    final db = await database;

    return await db.delete(
      "order_items",
      where: "id=?",
      whereArgs: [id],
    );
  }

  Future<int> deleteItemsByOrder(int orderId) async {
    final db = await database;

    return await db.delete(
      "order_items",
      where: "orderId=?",
      whereArgs: [orderId],
    );
  }

  //======================== SAVE COMPLETE ORDER ========================//

  Future<void> insertCompleteOrder(
      Order order,
      List<OrderItem> items,
      ) async {
    final db = await database;

    await db.transaction((txn) async {

      final orderId = await txn.insert(
        "orders",
        order.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      for (final item in items) {
        await txn.insert(
          "order_items",
          item.copyWith(orderId: orderId).toMap(),
        );
      }
    });
  }

  //======================== REPORT HELPERS ========================//

  Future<List<Map<String, dynamic>>> getOrderDetails(
      int orderId,
      ) async {
    final db = await database;

    return await db.rawQuery('''
      SELECT
        oi.*,
        p.productId,
        p.name
      FROM order_items oi
      INNER JOIN products p
      ON oi.productId = p.id
      WHERE oi.orderId = ?
    ''', [orderId]);
  }

  Future<List<Map<String, dynamic>>> getAllOrdersWithClients() async {
    final db = await database;

    return await db.rawQuery('''
      SELECT
        o.*,
        c.name AS clientName,
        c.phone
      FROM orders o
      INNER JOIN clients c
      ON o.clientId = c.id
      ORDER BY o.orderDate DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getClientLedger(
      int clientId,
      ) async {
    final db = await database;

    return await db.rawQuery('''
      SELECT *
      FROM orders
      WHERE clientId = ?
      ORDER BY orderDate DESC
    ''', [clientId]);
  }
}