// database/database_helper.dart
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
      version: 3,
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
    if (oldVersion < 3) {
      // Add userId column to tables if upgrading from older versions
      await db.execute("ALTER TABLE products ADD COLUMN userId INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE clients ADD COLUMN userId INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE orders ADD COLUMN userId INTEGER DEFAULT 0");
    }
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
        userId INTEGER,
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
        userId INTEGER,
        clientId TEXT UNIQUE,
        name TEXT,
        phone TEXT,
        address TEXT,
        balance REAL,
        notes TEXT,
        createdAt TEXT
      )
    ''');

    //---------------- ORDERS ----------------//

    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
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
        discount REAL,

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

  Future<List<Product>> getProducts(int userId) async {
    final db = await database;

    final result = await db.query(
      "products",
      where: "userId=?",
      whereArgs: [userId],
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

  Future<int> getProductCount(int userId) async {
    final db = await database;

    final result =
    await db.rawQuery("SELECT COUNT(*) FROM products WHERE userId=?", [userId]);

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

  Future<List<Client>> getClients(int userId) async {
    final db = await database;

    final result = await db.query(
      "clients",
      where: "userId=?",
      whereArgs: [userId],
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

  Future<int> getClientCount(int userId) async {
    final db = await database;

    final result =
    await db.rawQuery("SELECT COUNT(*) FROM clients WHERE userId=?", [userId]);

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

  Future<List<Order>> getOrders(int userId) async {
    final db = await database;

    final result = await db.query(
      "orders",
      where: "userId=?",
      whereArgs: [userId],
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

  Future<int> getOrderCount(int userId) async {
    final db = await database;

    final result =
    await db.rawQuery("SELECT COUNT(*) FROM orders WHERE userId=?", [userId]);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> getTotalSales(int userId) async {
    final db = await database;

    final result = await db.rawQuery(
      "SELECT SUM(grandTotal) FROM orders WHERE userId=?", [userId]
    );

    if (result.first.values.first == null) {
      return 0.0;
    }

    return (result.first.values.first as num).toDouble();
  }

  Future<double> getTotalRemaining(int userId) async {
    final db = await database;

    final result = await db.rawQuery(
      "SELECT SUM(remainingAmount) FROM orders WHERE userId=?", [userId]
    );

    if (result.first.values.first == null) {
      return 0.0;
    }

    return (result.first.values.first as num).toDouble();
  }

  Future<double> getTotalReceived(int userId) async {
    final db = await database;

    final result = await db.rawQuery(
      "SELECT SUM(paidAmount) FROM orders WHERE userId=?", [userId]
    );

    if (result.first.values.first == null) {
      return 0.0;
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

        // Deduct inventory
        await txn.rawUpdate('''
          UPDATE products 
          SET boxes = boxes - ? 
          WHERE id = ?
        ''', [item.boxes, item.productId]);
      }

      // Update client balance
      await txn.rawUpdate('''
        UPDATE clients 
        SET balance = balance + ? 
        WHERE id = ?
      ''', [order.remainingAmount, order.clientId]);
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

  Future<List<Map<String, dynamic>>> getAllOrdersWithClients(int userId) async {
    final db = await database;

    return await db.rawQuery('''
      SELECT
        o.*,
        c.name AS clientName,
        c.phone
      FROM orders o
      INNER JOIN clients c
      ON o.clientId = c.id
      WHERE o.userId = ?
      ORDER BY o.orderDate DESC
    ''', [userId]);
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

  //======================== NEW REPORT METHODS ========================//

  Future<double> getTotalClientBalance(int userId) async {
    final db = await database;
    final result = await db.rawQuery("SELECT SUM(balance) FROM clients WHERE userId=?", [userId]);
    if (result.first.values.first == null) return 0.0;
    return (result.first.values.first as num).toDouble();
  }

  Future<double> getTotalInventoryValue(int userId) async {
    final db = await database;
    final result = await db.rawQuery("SELECT SUM(boxes * quantityPerBox * purchasePrice) FROM products WHERE userId=?", [userId]);
    if (result.first.values.first == null) return 0.0;
    return (result.first.values.first as num).toDouble();
  }

  Future<double> getTotalProfit(int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(oi.totalPrice - (oi.boxes * oi.quantityPerBox * p.purchasePrice)) 
      FROM order_items oi 
      INNER JOIN products p ON oi.productId = p.id
      WHERE p.userId = ?
    ''', [userId]);
    if (result.first.values.first == null) return 0.0;
    return (result.first.values.first as num).toDouble();
  }

  Future<double> getSpendingByDate(int userId, String startDate, String endDate) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(boxes * quantityPerBox * purchasePrice) 
      FROM products 
      WHERE userId = ? AND arrivalDate >= ? AND arrivalDate <= ?
    ''', [userId, startDate, endDate]);
    if (result.first.values.first == null) return 0.0;
    return (result.first.values.first as num).toDouble();
  }

  Future<double> getSalesByDate(int userId, String startDate, String endDate) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(grandTotal) 
      FROM orders 
      WHERE userId = ? AND orderDate >= ? AND orderDate <= ?
    ''', [userId, startDate, endDate]);
    if (result.first.values.first == null) return 0.0;
    return (result.first.values.first as num).toDouble();
  }

  Future<int> getTotalBoxes(int userId) async {
    final db = await database;
    final result = await db.rawQuery("SELECT SUM(boxes) FROM products WHERE userId=?", [userId]);
    if (result.first.values.first == null) return 0;
    return Sqflite.firstIntValue(result) ?? 0;
  }
}