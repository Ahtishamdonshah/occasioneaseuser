import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'availabilitycatering.dart';

class QuantityCatering extends StatefulWidget {
  final List<Map<String, dynamic>> selectedSubservices;
  final String cateringId;
  final List<String> timeSlots;

  const QuantityCatering({
    Key? key,
    required this.selectedSubservices,
    required this.cateringId,
    required this.timeSlots,
  }) : super(key: key);

  @override
  _QuantityCateringState createState() => _QuantityCateringState();
}

class _QuantityCateringState extends State<QuantityCatering> {
  final Map<String, int> _quantities = {};
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    for (var service in widget.selectedSubservices) {
      _quantities[service['name']] = 1;
    }
  }

  void _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _selectedTimeSlot = null;
      });
    }
  }

  Future<int> _getBookedCapacity(String date, String timeSlot) async {
    try {
      final bookings = await _firestore
          .collection('CateringBookings')
          .where('cateringId', isEqualTo: widget.cateringId)
          .where('date', isEqualTo: date)
          .where('timeSlot', isEqualTo: timeSlot)
          .get();

      int totalBooked = 0;
      for (var booking in bookings.docs) {
        totalBooked += (booking['totalQuantity'] ?? 0) as int;
      }
      return totalBooked;
    } catch (e) {
      print('Error fetching bookings: $e');
      return 0;
    }
  }

  void _navigateToAvailabilityCatering() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time slot')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvailabilityCatering(
          cateringId: widget.cateringId,
          timeSlots: widget.timeSlots,
          selectedSubservices: widget.selectedSubservices,
          quantities: _quantities,
          selectedDate: _selectedDate!,
          selectedTimeSlot: _selectedTimeSlot!,
          userId: user.uid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catering Booking Details"),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Price: \$${service['price']}'),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    setState(() {
                                      if (_quantities[service['name']]! > 1) {
                                        _quantities[service['name']] =
                                            _quantities[service['name']]! - 1;
                                      }
                                    });
                                  },
                                ),
                                Text('${_quantities[service['name']]}'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      _quantities[service['name']] =
                                          _quantities[service['name']]! + 1;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              const Text(
                'Select Date:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectDate,
                      child: Text(_selectedDate == null
                          ? 'Choose Date'
                          : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedDate != null) ...[
                const Text(
                  'Select Time Slot:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getAvailableTimeSlots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final availableSlots = snapshot.data ?? [];
                    return Column(
                      children: availableSlots.map((slot) {
                        final isAvailable = slot['available'] as bool;
                        return RadioListTile<String>(
                          title: Text(
                            '${slot['timeSlot']} ${isAvailable ? '' : '(Not Available)'}',
                          ),
                          value: slot['timeSlot'],
                          groupValue: _selectedTimeSlot,
                          onChanged: isAvailable
                              ? (value) {
                                  setState(() {
                                    _selectedTimeSlot = value;
                                  });
                                }
                              : null,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _navigateToAvailabilityCatering,
                  child: const Text('Proceed to Availability Check'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getAvailableTimeSlots() async {
    final List<Map<String, dynamic>> availableSlots = [];
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

    for (var slot in widget.timeSlots) {
      final bookedCapacity = await _getBookedCapacity(dateStr, slot);
      final totalCapacity = 2; // Replace with actual capacity from Firestore
      final isAvailable = bookedCapacity < totalCapacity;

      availableSlots.add({
        'timeSlot': slot,
        'available': isAvailable,
      });
    }

    return availableSlots;
  }
}
