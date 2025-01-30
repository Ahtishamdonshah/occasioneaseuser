import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AvailabilityCatering extends StatefulWidget {
  final String cateringId;
  final List<String> timeSlots;
  final List<Map<String, dynamic>> selectedSubservices;
  final Map<String, int> quantities;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String userId;

  const AvailabilityCatering({
    Key? key,
    required this.cateringId,
    required this.timeSlots,
    required this.selectedSubservices,
    required this.quantities,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.userId,
  }) : super(key: key);

  @override
  _AvailabilityCateringState createState() => _AvailabilityCateringState();
}

class _AvailabilityCateringState extends State<AvailabilityCatering> {
  double _totalPrice = 0.0;
  bool _isBooking = false; // Added booking state flag

  @override
  void initState() {
    super.initState();
    _calculateTotalPrice();
  }

  void _calculateTotalPrice() {
    double total = 0.0;
    for (var service in widget.selectedSubservices) {
      total += service['price'] * widget.quantities[service['name']]!;
    }
    setState(() {
      _totalPrice = total;
    });
  }

  Future<void> _bookCateringService() async {
    if (_isBooking) return; // Prevent multiple submissions

    setState(() => _isBooking = true);

    try {
      final bookingData = {
        'userId': widget.userId,
        'cateringId': widget.cateringId,
        'date': DateFormat('yyyy-MM-dd').format(widget.selectedDate),
        'timeSlot': widget.selectedTimeSlot,
        'services': widget.selectedSubservices
            .map((service) => {
                  'name': service['name'],
                  'quantity': widget.quantities[service['name']],
                  'price': service['price']
                })
            .toList(),
        'totalPrice': _totalPrice,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(), // Add server timestamp
      };

      // Check for existing bookings first
      final existingBookings = await FirebaseFirestore.instance
          .collection('CateringBookings')
          .where('userId', isEqualTo: widget.userId)
          .where('cateringId', isEqualTo: widget.cateringId)
          .where('date', isEqualTo: bookingData['date'])
          .where('timeSlot', isEqualTo: widget.selectedTimeSlot)
          .get();

      if (existingBookings.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You already have a booking for this slot')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('CateringBookings')
          .add(bookingData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catering Service Booked Successfully')),
      );

      // Navigate back after successful booking
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      print('Error booking catering service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to book catering service')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Check Catering Availability"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selected Catering Services:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...widget.selectedSubservices.map((service) {
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
                  onPressed: _isBooking ? null : _bookCateringService,
                  child: _isBooking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Book Catering Service'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
