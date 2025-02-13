// import 'package:flutter/material.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class StripePayment extends StatefulWidget {
//   final String price; // New parameter for price
//   const StripePayment({super.key, required this.price});

//   @override
//   State<StripePayment> createState() => _StripePaymentState();
// }

// class _StripePaymentState extends State<StripePayment> {
//   Map<String, dynamic>? paymentIntentData;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     Stripe.publishableKey =
//         'pk_test_51PXhhWHFN9uHDd0rnxsPH6aOs7EZGAvcTRHXCQAfQbYWbf7mqejZEfAfIogri0DqDBSxVKeKd7QuO0cP2SRxwb9h008QssWoSB';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Payment', style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue[700],
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.blue[700]!, Colors.blue[100]!],
//           ),
//         ),
//         child: SafeArea(
//           child: Center(
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(
//                       Icons.payment_rounded,
//                       size: 80,
//                       color: Colors.white,
//                     ),
//                     const SizedBox(height: 24),
//                     const Text(
//                       'Complete Your Payment',
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     const Text(
//                       'Secure payment powered by Stripe',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.white70,
//                       ),
//                     ),
//                     const SizedBox(height: 48),
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(24),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 10,
//                             offset: const Offset(0, 5),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         children: [
//                           Text(
//                             '\$${widget.price}', // Use the passed price here
//                             style: const TextStyle(
//                               fontSize: 36,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blue,
//                             ),
//                           ),
//                           const SizedBox(height: 24),
//                           SizedBox(
//                             width: double.infinity,
//                             height: 56,
//                             child: ElevatedButton(
//                               onPressed:
//                                   _isLoading ? null : () => _handlePayment(),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.blue,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               child: _isLoading
//                                   ? const SizedBox(
//                                       width: 24,
//                                       height: 24,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         valueColor:
//                                             AlwaysStoppedAnimation<Color>(
//                                                 Colors.white),
//                                       ),
//                                     )
//                                   : const Text(
//                                       'Pay Now',
//                                       style: TextStyle(
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     TextButton(
//                       onPressed: () => Navigator.pop(context, false),
//                       child: const Text(
//                         "Cancel Payment",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _handlePayment() async {
//     setState(() => _isLoading = true);
//     try {
//       await makePayment(
//           amount: widget.price, currency: "PKR"); // Pass the price here
//       Navigator.pop(context, true); // Return true if payment is successful
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Payment initiation failed: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       Navigator.pop(context, false); // Return false if payment fails
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> makePayment(
//       {required String amount, required String currency}) async {
//     try {
//       paymentIntentData = await createPaymentIntent(amount, currency);

//       if (paymentIntentData != null) {
//         await Stripe.instance.initPaymentSheet(
//           paymentSheetParameters: SetupPaymentSheetParameters(
//             paymentIntentClientSecret: paymentIntentData!['client_secret'],
//             merchantDisplayName: 'Occasion Ease',
//             style: ThemeMode.dark,
//             appearance: const PaymentSheetAppearance(
//               colors: PaymentSheetAppearanceColors(
//                 primary: Colors.blue,
//               ),
//               shapes: PaymentSheetShape(
//                 borderRadius: 12,
//                 shadow: PaymentSheetShadowParams(color: Colors.black),
//               ),
//             ),
//           ),
//         );

//         await displayPaymentSheet();
//       } else {
//         throw Exception("Failed to create payment intent");
//       }
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> displayPaymentSheet() async {
//     try {
//       await Stripe.instance.presentPaymentSheet();
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Payment Successfully completed'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } on StripeException catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Payment failed: ${e.error.localizedMessage}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       throw Exception('Payment failed: ${e.error.localizedMessage}');
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Payment failed: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       throw Exception('Payment failed: $e');
//     }
//   }

//   Future<Map<String, dynamic>?> createPaymentIntent(
//       String amount, String currency) async {
//     try {
//       Map<String, dynamic> body = {
//         'amount': amount,
//         'currency': currency,
//         'payment_method_types[]': 'card',
//       };

//       var response = await http.post(
//         Uri.parse('https://api.stripe.com/v1/payment_intents'),
//         body: body,
//         headers: {
//           'Authorization':
//               'Bearer sk_test_51PXhhWHFN9uHDd0r5S4iQd02YzaZg8KNMohuomTjZ9FOuvV4RsSltt7YZg2AyiSz5hpKUWEkryxHYGIhRNudkleC00YHAv93L3',
//           'Content-Type': 'application/x-www-form-urlencoded',
//         },
//       );

//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       } else {
//         throw Exception('Failed to create payment intent: ${response.body}');
//       }
//     } catch (e) {
//       throw Exception('Error creating payment intent: $e');
//     }
//   }
// }
