// lib/utils/password_helper.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHelper {
  /// Hashes the password using SHA-256.
  /// The returned hash is what should be stored in the database.
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// Verifies whether a plain-text password matches a stored hash.
  static bool verifyPassword(String password, String storedHash) {
    return hashPassword(password) == storedHash;
  }
}