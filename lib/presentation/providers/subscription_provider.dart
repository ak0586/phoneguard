import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_provider.dart';

class SubscriptionProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  final InAppPurchase _iap = InAppPurchase.instance;
  
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  bool _isLoading = true;
  String? _errorMessage;
  PurchaseDetails? _latestPurchase;

  PurchaseDetails? get latestPurchase => _latestPurchase;

  void clearLatestPurchase() {
    _latestPurchase = null;
    notifyListeners();
  }

  SubscriptionProvider(this.authProvider) {
    _init();
  }

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static const String monthlyId = 'pg_monthly_premium';
  static const String yearlyId = 'pg_yearly_premium';
  static const String lifetimeId = 'pg_lifetime_premium';

  void _init() {
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        _errorMessage = 'Purchase stream error: $error';
        notifyListeners();
      },
    );
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isAvailable = await _iap.isAvailable();
      if (_isAvailable) {
        const Set<String> kIds = {monthlyId, yearlyId, lifetimeId};
        final response = await _iap.queryProductDetails(kIds);
        
        if (response.error != null) {
          _errorMessage = response.error!.message;
        } else {
          _products = response.productDetails;
          // Sort by price
          _products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
        }
      } else {
        _errorMessage = 'Store not available on this device.';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        _isLoading = true;
        notifyListeners();
      } else {
        if (purchase.status == PurchaseStatus.error) {
          _errorMessage = purchase.error?.message ?? 'Unknown purchase error';
        } else if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
          await _deliverEntitlement(purchase);
          if (purchase.status == PurchaseStatus.purchased) {
            _latestPurchase = purchase;
          }
        }

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _deliverEntitlement(PurchaseDetails purchase) async {
    final uid = authProvider.user?.uid;
    if (uid == null) return;

    String tier = 'monthly';
    DateTime expiry;

    if (purchase.productID == lifetimeId) {
      tier = 'lifetime';
      expiry = DateTime.now().add(const Duration(days: 36500)); // 100 years
    } else if (purchase.productID == yearlyId) {
      tier = 'yearly';
      expiry = DateTime.now().add(const Duration(days: 365));
    } else {
      tier = 'monthly';
      expiry = DateTime.now().add(const Duration(days: 30));
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'subscriptionType': tier,
        'subscriptionStatus': 'active',
        'isPremium': true,
        'protectionExpiry': Timestamp.fromDate(expiry),
        'purchaseToken': purchase.purchaseID,
      });
    } catch (e) {
      debugPrint('Error delivering entitlement: $e');
    }
  }

  Future<void> buySubscription(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> restorePurchases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _iap.restorePurchases();
      // Wait a few seconds to see if the stream updates the profile
      await Future.delayed(const Duration(seconds: 3));
      
      _isLoading = false;
      notifyListeners();
      
      // Return true if the user is now premium
      return authProvider.profile?.isPremium ?? false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
