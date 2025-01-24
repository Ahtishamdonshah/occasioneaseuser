import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class availabilityfarm extends StatefulWidget {
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, int> quantities;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String farmId;
  final double pricePerSeat;

  const availabilityfarm({
    Key? key,
    required this.selectedServices,
    required this.quantities,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.farmId,
    required this.pricePerSeat,
    required String timeSlot,
    required String marriageHallId,
  }) : super(key: key);

  @override
  _availabilityfarmState createState() => _availabilityfarmState();
}

class _availabilityfarmState extends State<availabilityfarm> {
  double _totalPrice = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculateTotalPrice();
  }

  // Calculate total price based on selected services, quantities, and pricePerSeat
  void _calculateTotalPrice() {
    double total = 0.0;
    for (var service in widget.selectedServices) {
      final price = service['price'] ?? 0.0;
      final quantity = widget.quantities[service['name']] ?? 1;
      total += price * quantity;
    }
    // Add pricePerSeat to the total price calculation
    total += widget.pricePerSeat; // Simply add pricePerSeat
    setState(() {
      _totalPrice = total;
    });
  }

  Future<void> _bookFarmService() async {
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        setState(() => _isLoading = false);
        return;
      }

      await FirebaseFirestore.instance.collection('FarmBookings').add({
        'userId': user.uid,
        'farmId': widget.farmId,
        'date': DateFormat('yyyy-MM-dd').format(widget.selectedDate),
        'timeSlot': widget.selectedTimeSlot,
        'services': widget.selectedServices
            .map((service) => {
                  'name': service['name'],
                  'quantity': widget.quantities[service['name']],
                  'price': service['price']
                })
            .toList(),
        'totalPrice': _totalPrice,
        'status': 'Pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm Service Booked Successfully')),
      );

      // Navigate back or to another page if needed
    } catch (e) {
      print('Error booking farm service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to book farm service')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Check Farm Availability"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selected Farm Services:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...widget.selectedServices.map((service) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['name'],
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Price: \$${service['price']}'),
                        Text('Quantity: ${widget.quantities[service['name']]}'),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              const Text(
                'Selected Date:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(DateFormat('yyyy-MM-dd').format(widget.selectedDate)),
              const SizedBox(height: 16),
              const Text(
                'Selected Time Slot:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(widget.selectedTimeSlot),
              const SizedBox(height: 16),
              const Text(
                'Total Price:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('\$$_totalPrice'),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _bookFarmService,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Book Farm Service'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
