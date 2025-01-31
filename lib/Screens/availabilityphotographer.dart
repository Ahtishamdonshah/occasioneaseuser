import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvailabilityPhotographer extends StatefulWidget {
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, int> quantities;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String photographerId;
  final List<Map<String, dynamic>> timeSlots;

  const AvailabilityPhotographer({
    Key? key,
    required this.selectedServices,
    required this.quantities,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.photographerId,
    required this.timeSlots,
  }) : super(key: key);

  @override
  _AvailabilityPhotographerState createState() =>
      _AvailabilityPhotographerState();
}

class _AvailabilityPhotographerState extends State<AvailabilityPhotographer> {
  double _totalPrice = 0.0;
  bool _isBooking = false;

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

  Future<void> _bookPhotographerService() async {
    setState(() => _isBooking = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Recheck availability
      final selectedDateStr =
          DateFormat('yyyy-MM-dd').format(widget.selectedDate);
      final bookingsQuery = await FirebaseFirestore.instance
          .collection('PhotographerBookings')
          .where('photographerId', isEqualTo: widget.photographerId)
          .where('date', isEqualTo: selectedDateStr)
          .where('timeSlot', isEqualTo: widget.selectedTimeSlot)
          .get();

      // Count existing bookings for this slot
      final int totalBooked = bookingsQuery.size;

      // Find slot capacity
      int slotCapacity = 0;
      for (var slot in widget.timeSlots) {
        final slotString = '${slot['startTime']} - ${slot['endTime']}';
        if (slotString == widget.selectedTimeSlot) {
          slotCapacity = slot['capacity'] ?? 0;
          break;
        }
      }

      // Check capacity (1 booking = 1 slot)
      if (totalBooked >= slotCapacity) {
        throw Exception('Slot no longer available');
      }

      // Create booking (services quantities are stored but don't affect availability)
      await FirebaseFirestore.instance.collection('PhotographerBookings').add({
        'userId': user.uid,
        'photographerId': widget.photographerId,
        'date': selectedDateStr,
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
        const SnackBar(content: Text('Booking successful!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Booking")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected Services:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...widget.selectedServices.map((service) => Card(
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
                        Text('Price: \$${service['price']}'),
                        Text('Quantity: ${widget.quantities[service['name']]}'),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            const Text(
              'Booking Details:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: const Text('Date'),
              subtitle:
                  Text(DateFormat('yyyy-MM-dd').format(widget.selectedDate)),
            ),
            ListTile(
              title: const Text('Time Slot'),
              subtitle: Text(widget.selectedTimeSlot),
            ),
            ListTile(
              title: const Text('Total Price'),
              subtitle: Text('\$$_totalPrice'),
            ),
            const SizedBox(height: 20),
            Center(
              child: _isBooking
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _bookPhotographerService,
                      child: const Text('Confirm Booking'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
