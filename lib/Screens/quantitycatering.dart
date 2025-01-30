import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'availabilitycatering.dart';

class QuantityCatering extends StatefulWidget {
  final List<Map<String, dynamic>> selectedSubservices;
  final String cateringId;
  final List<Map<String, dynamic>> timeSlots;

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
  Map<String, int> _availableCapacities = {};
  bool _isLoading = false;
  bool _isBooking = false; // Added booking state flag

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
        _isLoading = true;
      });

      await _calculateAvailableCapacities(pickedDate);

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateAvailableCapacities(DateTime selectedDate) async {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final bookingsQuery = await _firestore
        .collection('CateringBookings')
        .where('cateringId', isEqualTo: widget.cateringId)
        .where('date', isEqualTo: selectedDateStr)
        .get();

    final Map<String, int> bookedQuantities = {};

    for (var bookingDoc in bookingsQuery.docs) {
      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final timeSlot = bookingData['timeSlot'] as String?;
      final services = bookingData['services'] as List<dynamic>?;

      if (timeSlot == null || services == null) continue;

      int totalQuantity = 0;
      for (var service in services) {
        totalQuantity += (service['quantity'] as int?) ?? 0;
      }

      bookedQuantities.update(
        timeSlot,
        (value) => value + totalQuantity,
        ifAbsent: () => totalQuantity,
      );
    }

    final Map<String, int> availableCapacities = {};

    for (var timeSlot in widget.timeSlots) {
      final startTime = timeSlot['startTime'] as String? ?? '';
      final endTime = timeSlot['endTime'] as String? ?? '';
      final capacity = (timeSlot['capacity'] as int?) ?? 0;
      final timeSlotString = '$startTime - $endTime';

      final booked = bookedQuantities[timeSlotString] ?? 0;
      final available = capacity - booked;

      availableCapacities[timeSlotString] = available;
    }

    setState(() {
      _availableCapacities = availableCapacities;
    });
  }

  Future<void> _bookAppointment() async {
    if (_isBooking) return;
    setState(() => _isBooking = true);

    try {
      if (_selectedDate == null || _selectedTimeSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date and time slot')),
        );
        return;
      }

      final availableCapacity = _availableCapacities[_selectedTimeSlot!] ?? 0;
      if (availableCapacity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('This time slot is no longer available')),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AvailabilityCatering(
            cateringId: widget.cateringId,
            timeSlots: widget.timeSlots
                .map((slot) => '${slot['startTime']} - ${slot['endTime']}')
                .toList(),
            selectedSubservices: widget.selectedSubservices,
            quantities: _quantities,
            selectedDate: _selectedDate!,
            selectedTimeSlot: _selectedTimeSlot!,
            userId: user.uid,
          ),
        ),
      ).then((_) => setState(() => _isBooking = false));
    } catch (e) {
      print('Error booking appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to book appointment')),
      );
    } finally {
      if (mounted && _isBooking) {
        setState(() => _isBooking = false);
      }
    }
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
                _isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: widget.timeSlots.map((timeSlot) {
                          final startTime =
                              timeSlot['startTime'] as String? ?? '';
                          final endTime = timeSlot['endTime'] as String? ?? '';
                          final timeSlotString = '$startTime - $endTime';
                          final availableCapacity =
                              _availableCapacities[timeSlotString] ?? 0;
                          final isAvailable = availableCapacity > 0;

                          return RadioListTile<String>(
                            title: Text(
                                '$timeSlotString ($availableCapacity available)'),
                            subtitle: !isAvailable
                                ? const Text('Not available',
                                    style: TextStyle(color: Colors.red))
                                : null,
                            value: timeSlotString,
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
                      ),
              ],
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: (!_isBooking && // Added booking state check
                          _selectedTimeSlot != null &&
                          (_availableCapacities[_selectedTimeSlot!] ?? 0) > 0)
                      ? _bookAppointment
                      : null,
                  child: _isBooking
                      ? const CircularProgressIndicator()
                      : const Text('Book Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
