import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';

class SubscriptionProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  late Razorpay _razorpay;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Razorpay Keys (Should match backend and your Razorpay dashboard)
  static const String razorpayKeyId = 'rzp_test_T9JiUpdjbI85MT'; 
  
  // Vercel Backend URL (Use your deployed URL here, e.g., https://backend-phoneguard.vercel.app)
  // For local testing use your local IP, e.g. 'http://10.0.2.2:3000' for emulator
  static const String backendUrl = 'http://10.0.2.2:3000'; 
  
  // Your Razorpay Plan IDs from Dashboard
  static const String monthlyPlanId = 'plan_monthly_id'; // Replace with actual Plan ID
  static const String yearlyPlanId = 'plan_yearly_id';   // Replace with actual Plan ID

  SubscriptionProvider(this.authProvider) {
    _initRazorpay();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  // Common UI format mapping
  final List<Map<String, dynamic>> products = [
    {
      'id': 'pg_monthly_premium',
      'title': 'Monthly',
      'price': '₹99/mo',
      'rawPrice': 99.0,
      'description': 'Full access for one month'
    },
    {
      'id': 'pg_yearly_premium',
      'title': 'Yearly',
      'price': '₹899/yr',
      'rawPrice': 899.0,
      'description': 'Full access for one year (Save ~25%)'
    },
    {
      'id': 'pg_lifetime_premium',
      'title': 'Lifetime',
      'price': '₹2499',
      'rawPrice': 2499.0,
      'description': 'One-time payment for lifetime access'
    }
  ];

  Future<void> buySubscription(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = authProvider.user;
      if (user == null) throw Exception("User not logged in");

      Map<String, dynamic> responseData;

      if (productId == 'pg_lifetime_premium') {
        // One-time payment (Order)
        final res = await http.post(
          Uri.parse('$backendUrl/api/createOrder'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'amount': 2499,
            'receipt': 'rcpt_${user.uid.substring(0, 5)}_${DateTime.now().millisecondsSinceEpoch}',
          }),
        );
        responseData = jsonDecode(res.body);
        if (res.statusCode != 200) throw Exception(responseData['error']);
      } else {
        // Subscription (Monthly / Yearly)
        final planId = productId == 'pg_yearly_premium' ? yearlyPlanId : monthlyPlanId;
        final res = await http.post(
          Uri.parse('$backendUrl/api/createSubscription'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'plan_id': planId}),
        );
        responseData = jsonDecode(res.body);
        if (res.statusCode != 200) throw Exception(responseData['error']);
      }

      var options = {
        'key': razorpayKeyId,
        'name': 'PhoneGuard Premium',
        'description': productId == 'pg_lifetime_premium' ? 'Lifetime Access' : 'Premium Subscription',
        'prefill': {
          'email': user.email ?? '',
        },
        'notes': {
          'uid': user.uid,
          'tier': productId,
        }
      };

      if (productId == 'pg_lifetime_premium') {
        options['order_id'] = responseData['id'];
      } else {
        options['subscription_id'] = responseData['id'];
      }

      _razorpay.open(options);

    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Payment succeeded
    try {
      // In a real production app, verification should happen in the Webhook or Backend
      // Here we assume if Razorpay SDK returns success, we grant access immediately for better UX
      
      final uid = authProvider.user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'subscriptionStatus': 'active',
          'isPremium': true,
          'purchaseToken': response.paymentId ?? response.orderId,
        });
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating Firestore on client: $e");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _errorMessage = response.message ?? "Payment failed";
    _isLoading = false;
    notifyListeners();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> restorePurchases() async {
    // Restoring subscriptions typically involves checking your own backend/Firestore 
    // or Razorpay dashboard to see if user has an active subscription.
    // For now, we return their existing state in Firestore.
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 2));
    
    _isLoading = false;
    notifyListeners();
    return authProvider.profile?.isPremium ?? false;
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}
