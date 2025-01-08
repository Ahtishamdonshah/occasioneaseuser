import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AvailabilityPhotography extends StatefulWidget {
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, int> quantities;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String userId;
  final String photographerId;

  const AvailabilityPhotography({
    Key? key,
    required this.selectedServices,
    required this.quantities,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.userId,
    required this.photographerId,
  }) : super(key: key);

  @override
  _AvailabilityPhotographyState createState() =>
      _AvailabilityPhotographyState();
}

class _AvailabilityPhotographyState extends State<AvailabilityPhotography> {
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotalPrice();
  }

  void _calculateTotalPrice() {
    double total = 0.0;
    for (var service in widget.selectedServices) {
      total += service['price'] * (widget.quantities[service['name']] ?? 0);
    }
    setState(() {
      _totalPrice = total;
    });
  }

  Future<void> _bookPhotographyService() async {
    try {
      await FirebaseFirestore.instance.collection('PhotographerBookings').add({
        'userId': widget.userId,
        'photographerId': widget.photographerId,
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
        const SnackBar(
            content: Text('Photography Service Booked Successfully')),
      );

      // Navigate back or to another page if needed
    } catch (e) {
      print('Error booking photography service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to book photography service')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Check Photography Availability"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selected Photography Services:',
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
                  onPressed: _bookPhotographyService,
                  child: const Text('Book Photography Service'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
