// database/database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user.dart';
import '../models/product.dart';
import '../models/client.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/payment.dart';
import '../models/batch.dart';

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
      version: 8,
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
      await db.execute("ALTER TABLE products ADD COLUMN userId INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE clients ADD COLUMN userId INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE orders ADD COLUMN userId INTEGER DEFAULT 0");
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE order_items ADD COLUMN loosePieces INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE products ADD COLUMN totalPieces INTEGER DEFAULT 0");
      await db.execute("UPDATE products SET totalPieces = boxes * quantityPerBox");
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE payments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          clientId INTEGER,
          amount REAL,
          date TEXT,
          notes TEXT,
          FOREIGN KEY(clientId) REFERENCES clients(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 6) {
      try {
        await db.execute("ALTER TABLE order_items ADD COLUMN costPrice REAL DEFAULT 0");
      } catch (e) {}
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS batches(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productId INTEGER,
          quantityPurchased INTEGER,
          quantityRemaining INTEGER,
          purchasePrice REAL,
          purchaseDate TEXT,
          FOREIGN KEY(productId) REFERENCES products(id) ON DELETE CASCADE
        )
      ''');

      final batchCount = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM batches")) ?? 0;
      if (batchCount == 0) {
        final products = await db.query('products');
        for (var p in products) {
          final totalPieces = p['totalPieces'] as int? ?? 0;
          if (totalPieces > 0) {
            await db.insert('batches', {
              'productId': p['id'],
              'quantityPurchased': totalPieces,
              'quantityRemaining': totalPieces,
              'purchasePrice': p['purchasePrice'],
              'purchaseDate': p['arrivalDate'],
            });
          }
        }
      }
    }
    if (oldVersion < 7) {
      try {
        await db.execute("ALTER TABLE orders ADD COLUMN totalAmount REAL DEFAULT 0");
        await db.execute("ALTER TABLE orders ADD COLUMN discount REAL DEFAULT 0");
        await db.execute("UPDATE orders SET totalAmount = grandTotal");
      } catch (e) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute("ALTER TABLE orders ADD COLUMN previousBalance REAL DEFAULT 0");
      } catch (e) {}
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        productId TEXT UNIQUE,
        name TEXT,
        description TEXT,
        totalPieces INTEGER,
        quantityPerBox INTEGER,
        purchasePrice REAL,
        arrivalDate TEXT
      )
    ''');

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

    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        orderNo TEXT UNIQUE,
        clientId INTEGER,
        orderDate TEXT,
        totalAmount REAL,
        discount REAL,
        grandTotal REAL,
        previousBalance REAL,
        paidAmount REAL,
        remainingAmount REAL,
        status TEXT,
        remarks TEXT,
        FOREIGN KEY(clientId) REFERENCES clients(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER,
        productId INTEGER,
        boxes INTEGER,
        loosePieces INTEGER,
        quantityPerBox INTEGER,
        sellingPrice REAL,
        totalPrice REAL,
        discount REAL,
        costPrice REAL,
        FOREIGN KEY(orderId) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY(productId) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER,
        amount REAL,
        date TEXT,
        notes TEXT,
        FOREIGN KEY(clientId) REFERENCES clients(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE batches(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER,
        quantityPurchased INTEGER,
        quantityRemaining INTEGER,
        purchasePrice REAL,
        purchaseDate TEXT,
        FOREIGN KEY(productId) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');
  }

  //======================== USERS ========================//
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert("users", user.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<User?> login(String username, String password) async {
    final db = await database;
    final result = await db.query("users", where: "username=? AND password=?", whereArgs: [username, password]);
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  Future<bool> usernameExists(String username) async {
    final db = await database;
    final result = await db.query("users", where: "username=?", whereArgs: [username]);
    return result.isNotEmpty;
  }

  Future<String?> getUsername(int userId) async {
    final db = await database;
    final result = await db.query("users", columns: ["username"], where: "id=?", whereArgs: [userId]);
    if (result.isEmpty) return null;
    return result.first["username"] as String?;
  }

  //======================== PRODUCTS ========================//
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.transaction((txn) async {
      final id = await txn.insert("products", product.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
      if (product.totalPieces > 0) {
        await txn.insert("batches", {
          "productId": id,
          "quantityPurchased": product.totalPieces,
          "quantityRemaining": product.totalPieces,
          "purchasePrice": product.purchasePrice,
          "purchaseDate": product.arrivalDate,
        });
      }
      return id;
    });
  }

  Future<bool> productIdExists(String productId, {int? excludeId}) async {
    final db = await database;
    final result = await db.query(
      "products",
      where: excludeId == null ? "productId=?" : "productId=? AND id!=?",
      whereArgs: excludeId == null ? [productId] : [productId, excludeId],
    );
    return result.isNotEmpty;
  }

  Future<List<Product>> getProducts(int userId) async {
    final db = await database;
    final result = await db.query("products", where: "userId=?", whereArgs: [userId], orderBy: "name ASC");
    return result.map((e) => Product.fromMap(e)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final result = await db.query("products", where: "id=?", whereArgs: [id]);
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update("products", product.toMap(), where: "id=?", whereArgs: [product.id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete("products", where: "id=?", whereArgs: [id]);
  }

  Future<int> getProductCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery("SELECT COUNT(*) FROM products WHERE userId=?", [userId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  //======================== CLIENTS ========================//
  Future<int> insertClient(Client client) async {
    final db = await database;
    return await db.insert("clients", client.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<Client>> getClients(int userId) async {
    final db = await database;
    final result = await db.query("clients", where: "userId=?", whereArgs: [userId], orderBy: "name ASC");
    return result.map((e) => Client.fromMap(e)).toList();
  }

  Future<Client?> getClientById(int id) async {
    final db = await database;
    final result = await db.query("clients", where: "id=?", whereArgs: [id]);
    if (result.isEmpty) return null;
    return Client.fromMap(result.first);
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    return await db.update("clients", client.toMap(), where: "id=?", whereArgs: [client.id]);
  }

  Future<int> deleteClient(int id) async {
    final db = await database;
    return await db.delete("clients", where: "id=?", whereArgs: [id]);
  }

  Future<int> getClientCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery("SELECT COUNT(*) FROM clients WHERE userId=?", [userId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  //======================== PAYMENTS ========================//
  Future<void> insertPayment(Payment payment) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert("payments", payment.toMap());

      await txn.rawUpdate(
        "UPDATE clients SET balance = balance - ? WHERE id = ?",
        [payment.amount, payment.clientId],
      );

      double remainingPayment = payment.amount;

      final List<Map<String, dynamic>> pendingOrders = await txn.rawQuery(
        "SELECT * FROM orders WHERE clientId = ? AND remainingAmount > 0 ORDER BY id ASC",
        [payment.clientId],
      );

      for (var orderMap in pendingOrders) {
        if (remainingPayment <= 0) break;

        final order = Order.fromMap(orderMap);
        double amountToApply = remainingPayment >= order.remainingAmount
            ? order.remainingAmount
            : remainingPayment;

        double newPaidAmount = order.paidAmount + amountToApply;
        double newRemainingAmount = order.remainingAmount - amountToApply;
        String newStatus = newRemainingAmount <= 0 ? "Paid" : "Partially Paid";

        await txn.update(
          "orders",
          {
            "paidAmount": newPaidAmount,
            "remainingAmount": newRemainingAmount,
            "status": newStatus,
          },
          where: "id = ?",
          whereArgs: [order.id],
        );

        remainingPayment -= amountToApply;
      }
    });
  }

  Future<List<Payment>> getPaymentsByClient(int clientId) async {
    final db = await database;
    final result = await db.query(
      "payments",
      where: "clientId = ?",
      whereArgs: [clientId],
      orderBy: "date DESC",
    );
    return result.map((e) => Payment.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllPaymentsWithClientNames(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, c.name AS clientName
      FROM payments p
      INNER JOIN clients c ON p.clientId = c.id
      WHERE c.userId = ?
      ORDER BY p.date DESC
    ''', [userId]);
  }

  //======================== ORDERS ========================//
  Future<int> insertOrder(Order order) async {
    final db = await database;
    return await db.insert("orders", order.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<Order>> getOrders(int userId) async {
    final db = await database;
    final result = await db.query("orders", where: "userId=?", whereArgs: [userId], orderBy: "orderDate DESC");
    return result.map((e) => Order.fromMap(e)).toList();
  }

  Future<Order?> getOrderById(int id) async {
    final db = await database;
    final result = await db.query("orders", where: "id=?", whereArgs: [id]);
    if (result.isEmpty) return null;
    return Order.fromMap(result.first);
  }

  Future<List<Order>> getOrdersByClient(int clientId) async {
    final db = await database;
    final result = await db.query("orders", where: "clientId=?", whereArgs: [clientId], orderBy: "orderDate DESC");
    return result.map((e) => Order.fromMap(e)).toList();
  }

  Future<int> updateOrder(Order order) async {
    final db = await database;
    return await db.update("orders", order.toMap(), where: "id=?", whereArgs: [order.id]);
  }

  Future<int> deleteOrder(int id) async {
    final db = await database;
    return await db.delete("orders", where: "id=?", whereArgs: [id]);
  }

  Future<int> getOrderCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery("SELECT COUNT(*) FROM orders WHERE userId=?", [userId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> getTotalSales(int userId) async {
    final db = await database;
    final result = await db.rawQuery("SELECT SUM(grandTotal) FROM orders WHERE userId=?", [userId]);
    if (result.first.values.first == null) return 0.0;
    return (result.first.values.first as num).toDouble();
  }

  //======================== ORDER ITEMS ========================//
  Future<int> insertOrderItem(OrderItem item) async {
    final db = await database;
    return await db.insert("order_items", item.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final db = await database;
    final result = await db.query("order_items", where: "orderId=?", whereArgs: [orderId]);
    return result.map((e) => OrderItem.fromMap(e)).toList();
  }

  //======================== SAVE COMPLETE ORDER ========================//
  Future<void> insertCompleteOrder(Order order, List<OrderItem> items) async {
    final db = await database;
    await db.transaction((txn) async {
      final orderId = await txn.insert("orders", order.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
      for (final item in items) {
        int piecesRemainingToDeduct = (item.boxes * item.quantityPerBox) + item.loosePieces;
        double totalCostForSoldItem = 0.0;

        final List<Map<String, dynamic>> batches = await txn.rawQuery(
          "SELECT * FROM batches WHERE productId = ? AND quantityRemaining > 0 ORDER BY purchaseDate ASC",
          [item.productId],
        );

        for (var batchMap in batches) {
          if (piecesRemainingToDeduct <= 0) break;

          int batchId = batchMap['id'];
          int quantityRemainingInBatch = batchMap['quantityRemaining'];
          double purchasePrice = batchMap['purchasePrice'];

          int deduction = piecesRemainingToDeduct >= quantityRemainingInBatch
              ? quantityRemainingInBatch
              : piecesRemainingToDeduct;

          await txn.rawUpdate(
            "UPDATE batches SET quantityRemaining = quantityRemaining - ? WHERE id = ?",
            [batchId, deduction],
          );

          totalCostForSoldItem += deduction * purchasePrice;
          piecesRemainingToDeduct -= deduction;
        }

        await txn.insert("order_items", item.copyWith(orderId: orderId, costPrice: totalCostForSoldItem).toMap());

        int totalSold = (item.boxes * item.quantityPerBox) + item.loosePieces;
        await txn.rawUpdate('''
          UPDATE products 
          SET totalPieces = totalPieces - ? 
          WHERE id = ?
        ''', [totalSold, item.productId]);
      }
      
      await txn.rawUpdate('''
        UPDATE clients 
        SET balance = balance + ? 
        WHERE id = ?
      ''', [order.grandTotal, order.clientId]);
    });
  }

  //======================== REPORT HELPERS ========================//
  Future<List<Map<String, dynamic>>> getOrderDetails(int orderId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT oi.*, p.productId, p.name
      FROM order_items oi
      INNER JOIN products p ON oi.productId = p.id
      WHERE oi.orderId = ?
    ''', [orderId]);
  }

  Future<List<Map<String, dynamic>>> getAllOrdersWithClients(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT o.*, c.name AS clientName, c.phone, c.address, c.balance AS currentClientBalance
      FROM orders o
      INNER JOIN clients c ON o.clientId = c.id
      WHERE o.userId = ?
      ORDER BY o.orderDate DESC
    ''', [userId]);
  }

  Future<double> getTotalClientBalance(int userId) async {
    final db = await database;
    final result = await db.rawQuery("SELECT SUM(balance) FROM clients WHERE userId=?", [userId]);
    if (result.first.values.first == null) return 0.0;
    return (result.first.values.first as num).toDouble();
  }

  Future<double> getTotalInventoryValue(int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(b.quantityRemaining * b.purchasePrice) 
      FROM batches b
      INNER JOIN products p ON b.productId = p.id
      WHERE p.userId = ?
    ''', [userId]);
    if (result.first.values.first == null) return 0.0;
    return (result.first.values.first as num).toDouble();
  }

  Future<double> getTotalProfit(int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(oi.totalPrice - oi.costPrice) 
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
      SELECT SUM(b.quantityPurchased * b.purchasePrice) 
      FROM batches b
      INNER JOIN products p ON b.productId = p.id
      WHERE p.userId = ? AND b.purchaseDate >= ? AND b.purchaseDate <= ?
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
    final result = await db.rawQuery('''
      SELECT SUM(CASE WHEN quantityPerBox > 0 THEN totalPieces / quantityPerBox ELSE 0 END) 
      FROM products 
      WHERE userId=?
    ''', [userId]);
    if (result.first.values.first == null) return 0;
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> addStock(int productId, int pieces, double purchasePrice, String date) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert("batches", {
        "productId": productId,
        "quantityPurchased": pieces,
        "quantityRemaining": pieces,
        "purchasePrice": purchasePrice,
        "purchaseDate": date,
      });
      await txn.rawUpdate(
        "UPDATE products SET totalPieces = totalPieces + ?, purchasePrice = ?, arrivalDate = ? WHERE id = ?",
        [pieces, purchasePrice, date, productId],
      );
    });
  }

  Future<List<ProductBatch>> getBatchesForProduct(int productId) async {
    final db = await database;
    final result = await db.query(
      "batches",
      where: "productId = ?",
      whereArgs: [productId],
      orderBy: "purchaseDate DESC",
    );
    return result.map((e) => ProductBatch.fromMap(e)).toList();
  }
}
