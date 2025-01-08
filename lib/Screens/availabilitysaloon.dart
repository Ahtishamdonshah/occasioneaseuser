import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AvailabilitySaloon extends StatefulWidget {
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, int> quantities;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String saloonId;
  final String userId;

  const AvailabilitySaloon({
    Key? key,
    required this.selectedServices,
    required this.quantities,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.saloonId,
    required this.userId,
    required List<String> timeSlots,
  }) : super(key: key);

  @override
  _AvailabilitySaloonState createState() => _AvailabilitySaloonState();
}

class _AvailabilitySaloonState extends State<AvailabilitySaloon> {
  bool _isLoading = false;
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotalPrice();
  }

  void _calculateTotalPrice() {
    double total = 0.0;
    for (var service in widget.selectedServices) {
      final price = service['price'] as double;
      final quantity = widget.quantities[service['name']]!;
      total += price * quantity;
    }
    setState(() {
      _totalPrice = total;
    });
  }

  Future<void> _bookSaloon() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookingData = {
        'userId': widget.userId,
        'saloonId': widget.saloonId,
        'selectedDate': widget.selectedDate,
        'selectedTimeSlot': widget.selectedTimeSlot,
        'selectedServices': widget.selectedServices,
        'quantities': widget.quantities,
        'totalPrice': _totalPrice,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('saloonbookings')
          .add(bookingData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking successful')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error booking saloon: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to book saloon')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Availability Check"),
      ),
      body: SingleChildScrollView(
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
                      const SizedBox(height: 8),
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
            Text(
              DateFormat('yyyy-MM-dd').format(widget.selectedDate),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selected Time Slot:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.selectedTimeSlot,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Price: \$${_totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _bookSaloon,
                      child: const Text('Book Now'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
