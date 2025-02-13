import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:occasioneaseuser/Screens/succesfull.dart';

// Assuming this page exists for booking success
class availabilityfarm extends StatefulWidget {
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, int> quantities;
  final DateTime selectedDate;
  final Map<String, dynamic> selectedTimeSlot;
  final double pricePerSeat;
  final int numberOfPersons;
  final String farmhouseId;
  final Map<String, dynamic> farmhouseData;

  const availabilityfarm({
    Key? key,
    required this.selectedServices,
    required this.quantities,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.pricePerSeat,
    required this.numberOfPersons,
    required this.farmhouseId,
    required this.farmhouseData,
  }) : super(key: key);

  @override
  _availabilityfarmState createState() => _availabilityfarmState();
}

class _availabilityfarmState extends State<availabilityfarm> {
  late double _totalPrice;
  bool _isAvailable = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _calculateTotalPrice();
  }

  void _calculateTotalPrice() {
    double basePrice = widget.numberOfPersons * widget.pricePerSeat;
    double servicesTotal = widget.selectedServices.fold(0.0, (sum, service) {
      return sum + (service['price'] * widget.quantities[service['name']]!);
    });
    _totalPrice = basePrice + servicesTotal;
  }

  Future<void> _checkAvailability() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.uid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated. Please login.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
      final bookings = await FirebaseFirestore.instance
          .collection('FarmBookings')
          .where('farmhouseId', isEqualTo: widget.farmhouseId)
          .where('date', isEqualTo: dateStr)
          .where('timeSlot', isEqualTo: widget.selectedTimeSlot)
          .get();

      setState(() {
        _isAvailable =
            bookings.docs.isEmpty; // If no bookings exist for this slot
      });

      if (_isAvailable) {
        await FirebaseFirestore.instance.collection('FarmBookings').add({
          'userId': user.uid,
          'farmhouseId': widget.farmhouseId,
          'date': dateStr,
          'timeSlot': widget.selectedTimeSlot,
          'numberOfPersons': widget.numberOfPersons,
          'totalPrice': _totalPrice,
          'services': widget.selectedServices.map((service) {
            return {
              'name': service['name'],
              'quantity': widget.quantities[service['name']],
              'price': service['price']
            };
          }).toList(),
          'status': 'BOOKED',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Slot is available and booked!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BookingSuccessPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Slot is already booked!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking availability: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability Check',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Booking Summary',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    const Divider(),
                    Text(
                        'Date: ${DateFormat.yMd().format(widget.selectedDate)}',
                        style: const TextStyle(fontSize: 16)),
                    Text('Time Slot: ${widget.selectedTimeSlot}',
                        style: const TextStyle(fontSize: 16)),
                    Text('Persons: ${widget.numberOfPersons}',
                        style: const TextStyle(fontSize: 16)),
                    Text(
                        'Base Price: \$${(widget.numberOfPersons * widget.pricePerSeat).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    ...widget.selectedServices.map((service) => ListTile(
                          title: Text(service['name'],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700)),
                          trailing: Text(
                              '\$${(service['price'] * widget.quantities[service['name']]!).toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.blue.shade900)),
                          subtitle: Text(
                              'Quantity: ${widget.quantities[service['name']]}'),
                        )),
                    const Divider(),
                    Text('Total Price: \$${_totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkAvailability,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Check Availability and Book',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
