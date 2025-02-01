import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:occasioneaseuser/Screens/succesfull.dart'; // Make sure to import your success page

class AvailabilitySaloon extends StatefulWidget {
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, int> quantities;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String salonId;

  const AvailabilitySaloon({
    Key? key,
    required this.selectedServices,
    required this.quantities,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.salonId,
  }) : super(key: key);

  @override
  _AvailabilitySaloonState createState() => _AvailabilitySaloonState();
}

class _AvailabilitySaloonState extends State<AvailabilitySaloon> {
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotalPrice();
  }

  void _calculateTotalPrice() {
    double total = 0.0;
    for (var service in widget.selectedServices) {
      total += service['price'] * widget.quantities[service['name']]!;
    }
    setState(() {
      _totalPrice = total;
    });
  }

  Future<void> _bookSalonService() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('SaloonBookings').add({
        'userId': user.uid,
        'salonId': widget.salonId,
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
        'status': 'BOOKED',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salon service booked successfully!')),
      );

      // Navigate to BookingSuccessPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                BookingSuccessPage()), // Make sure you have your BookingSuccessPage widget defined
      );
    } catch (e) {
      print('Error booking salon service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to book salon service')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Salon Availability"),
        backgroundColor: Colors.blue, // Blue app bar color
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selected Salon Services:',
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
                  onPressed: _bookSalonService,
                  child: const Text('Book Salon Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.blue, // Blue background for the button
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
