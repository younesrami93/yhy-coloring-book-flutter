import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/user_model.dart';

class PurchaseService {
  // TODO: Add your API Keys from RevenueCat Dashboard
  static const _apiKeyAndroid = 'goog_...';
  static const _apiKeyIOS = 'appl_...';

  static Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKeyAndroid);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_apiKeyIOS);
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
    }
  }

  /// Identifies the user in RevenueCat.
  /// Call this after your Guest or Social Login succeeds.
  static Future<void> identifyUser(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      // Handle error
    }
  }

  /// Logout from RevenueCat when user logs out
  static Future<void> logout() async {
    await Purchases.logOut();
  }

  /// Fetch available packages (e.g., 10 Credits, 50 Credits)
  Future<List<Package>> fetchPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      // "credits_page" should be the Offering Identifier you set in RevenueCat
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        return offerings.current!.availablePackages;
      }
    } catch (e) {
      print("Error fetching packages: $e");
    }
    return [];
  }

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      // The purchase was successful on the Store.
      // NOTE: Your Backend should ideally listen to RevenueCat webhooks
      // to update the credits on the server side securely.
      return true;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        print("Purchase Error: $e");
      }
      return false;
    }
  }
}