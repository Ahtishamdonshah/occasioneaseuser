import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _calculateTotalPrice();
  }

  void _calculateTotalPrice() {
    double basePrice = widget.numberOfPersons * widget.pricePerSeat;
    double servicesPrice = widget.selectedServices.fold(0.0, (sum, service) {
      return sum + (service['price'] * widget.quantities[service['name']]!);
    });
    setState(() => _totalPrice = basePrice + servicesPrice);
  }

  Future<void> _checkAvailability() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('FarmBookings')
          .where('farmhouseId', isEqualTo: widget.farmhouseId)
          .where('date',
              isEqualTo: DateFormat('yyyy-MM-dd').format(widget.selectedDate))
          .where('timeSlot', isEqualTo: widget.selectedTimeSlot)
          .get();

      setState(() => _isAvailable = query.docs.isEmpty);

      if (_isAvailable) {
        await FirebaseFirestore.instance.collection('FarmBookings').add({
          'farmhouseId': widget.farmhouseId,
          'date': DateFormat('yyyy-MM-dd').format(widget.selectedDate),
          'timeSlot': widget.selectedTimeSlot,
          'numberOfPersons': widget.numberOfPersons,
          'totalPrice': _totalPrice,
          'services': widget.selectedServices
              .map((service) => {
                    'name': service['name'],
                    'quantity': widget.quantities[service['name']],
                    'price': service['price']
                  })
              .toList(),
          'status': 'Confirmed',
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Slot available and booked successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot already booked')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error checking availability')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Availability Check")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Booking Summary:', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            Text(
                'Date: ${DateFormat('yyyy-MM-dd').format(widget.selectedDate)}'),
            Text('Time Slot: ${widget.selectedTimeSlot}'),
            Text('Number of Persons: ${widget.numberOfPersons}'),
            const SizedBox(height: 20),
            const Text('Services:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...widget.selectedServices.map((service) => ListTile(
                  title: Text(service['name']),
                  trailing: Text(
                      '${widget.quantities[service['name']]} x \$${service['price']}'),
                )),
            const SizedBox(height: 20),
            Text('Total Price: \$${_totalPrice.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _checkAvailability,
                child: const Text('Check Availability'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 0),
    );
  }

  BottomNavigationBar _buildBottomNavBar(BuildContext context, int index) {
    return BottomNavigationBar(
      currentIndex: index,
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
