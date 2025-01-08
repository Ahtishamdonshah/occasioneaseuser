import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AvailabilityMarriageHall extends StatefulWidget {
  final String hallId;
  final List<String> timeSlots;
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, int> quantities;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String userId;

  const AvailabilityMarriageHall({
    Key? key,
    required this.hallId,
    required this.timeSlots,
    required this.selectedServices,
    required this.quantities,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.userId,
  }) : super(key: key);

  @override
  _AvailabilityMarriageHallState createState() =>
      _AvailabilityMarriageHallState();
}

class _AvailabilityMarriageHallState extends State<AvailabilityMarriageHall> {
  bool _isAvailable = false;
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

  Future<void> _checkAvailability() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('MarriageHallBookings')
          .where('hallId', isEqualTo: widget.hallId)
          .where('date',
              isEqualTo: DateFormat('yyyy-MM-dd').format(widget.selectedDate))
          .where('timeSlot', isEqualTo: widget.selectedTimeSlot)
          .get();

      setState(() {
        _isAvailable = querySnapshot.docs.isEmpty;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isAvailable
              ? 'The selected slot is available'
              : 'The selected slot is not available'),
        ),
      );
    } catch (e) {
      print('Error checking availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to check availability')),
      );
    }
  }

  Future<void> _bookMarriageHall() async {
    if (!_isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected slot is not available')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('MarriageHallBookings').add({
        'userId': widget.userId,
        'hallId': widget.hallId,
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
        const SnackBar(content: Text('Marriage Hall Booked Successfully')),
      );

      // Navigate back or to another page if needed
    } catch (e) {
      print('Error booking marriage hall: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to book marriage hall')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Check Marriage Hall Availability"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selected Services:',
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
                  onPressed: _checkAvailability,
                  child: const Text('Check Availability'),
                ),
              ),
              const SizedBox(height: 16),
              if (_isAvailable)
                Center(
                  child: ElevatedButton(
                    onPressed: _bookMarriageHall,
                    child: const Text('Book Marriage Hall'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
