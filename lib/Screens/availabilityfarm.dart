import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AvailabilityFarm extends StatefulWidget {
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, int> quantities;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final double pricePerSeat;
  final int numberOfPersons;
  final String farmhouseId;

  const AvailabilityFarm({
    Key? key,
    required this.selectedServices,
    required this.quantities,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.pricePerSeat,
    required this.numberOfPersons,
    required this.farmhouseId,
  }) : super(key: key);

  @override
  _AvailabilityFarmState createState() => _AvailabilityFarmState();
}

class _AvailabilityFarmState extends State<AvailabilityFarm> {
  bool _isAvailable = false;
  double _totalPrice = 0.0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _calculateTotalPrice();
  }

  void _calculateTotalPrice() {
    double basePrice = widget.numberOfPersons * widget.pricePerSeat;
    double servicesPrice = widget.selectedServices.fold(0.0, (sum, service) {
      final price = service['price'] is String
          ? double.parse(service['price'])
          : service['price'] as double;
      return sum + (price * widget.quantities[service['name']]!);
    });
    setState(() => _totalPrice = basePrice + servicesPrice);
  }

  Future<void> _checkAvailability() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showSnackBar('Please login to book', Colors.red);
        return;
      }

      if (widget.selectedDate.isBefore(DateTime.now())) {
        _showSnackBar('Cannot book past dates', Colors.red);
        return;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

      final query = await FirebaseFirestore.instance
          .collection('FarmBookings')
          .where('farmhouseId', isEqualTo: widget.farmhouseId)
          .where('date', isEqualTo: dateStr)
          .where('timeSlot', isEqualTo: widget.selectedTimeSlot)
          .get();

      setState(() => _isAvailable = query.docs.isEmpty);

      if (_isAvailable) {
        await _createBooking(user, dateStr);
        _showSnackBar('Booking successful!', Colors.green);
      } else {
        _showSnackBar('Slot not available', Colors.orange);
      }
    } catch (e) {
      _showSnackBar('Error processing booking', Colors.red);
    }
  }

  Future<void> _createBooking(User user, String dateStr) async {
    await FirebaseFirestore.instance.collection('FarmBookings').add({
      'userId': user.uid,
      'farmhouseId': widget.farmhouseId,
      'date': dateStr,
      'timeSlot': widget.selectedTimeSlot,
      'numberOfPersons': widget.numberOfPersons,
      'totalPrice': _totalPrice,
      'services': widget.selectedServices.map((service) {
        final price = service['price'] is String
            ? double.parse(service['price'])
            : service['price'] as double;
        return {
          'name': service['name'],
          'quantity': widget.quantities[service['name']],
          'price': price
        };
      }).toList(),
      'status': 'BOOKED',
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Availability Check"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Booking Summary:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildDetailRow(
                'Date:', DateFormat('yyyy-MM-dd').format(widget.selectedDate)),
            _buildDetailRow('Time Slot:', widget.selectedTimeSlot),
            _buildDetailRow(
                'Number of Persons:', widget.numberOfPersons.toString()),
            const SizedBox(height: 20),
            const Text('Selected Services:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...widget.selectedServices.map((service) => ListTile(
                  title: Text(service['name'],
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Text(
                      '${widget.quantities[service['name']]} x \$${_formatPrice(service['price'])}'),
                  subtitle: Text(
                      'Total: \$${_calculateServiceTotal(service).toStringAsFixed(2)}'),
                )),
            const SizedBox(height: 20),
            _buildDetailRow(
                'Total Price:', '\$${_totalPrice.toStringAsFixed(2)}',
                isTotal: true),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _checkAvailability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text('Check Availability & Book',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 0),
    );
  }

  String _formatPrice(dynamic price) {
    return (price is double ? price : double.parse(price.toString()))
        .toStringAsFixed(2);
  }

  double _calculateServiceTotal(Map<String, dynamic> service) {
    final price = service['price'] is String
        ? double.parse(service['price'])
        : service['price'] as double;
    return price * widget.quantities[service['name']]!;
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16)),
          Text(value,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                  color: Colors.blue.shade800)),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar(BuildContext context, int index) {
    return BottomNavigationBar(
      currentIndex: index,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (idx) {
        if (idx == 1) Navigator.pushNamed(context, '/favorites');
        if (idx == 2) Navigator.pushNamed(context, '/profile');
      },
    );
  }
}
