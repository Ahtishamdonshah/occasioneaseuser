import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:occasioneaseuser/Screens/availabilityfarm.dart';

class QuantityAndDateFarmhouseScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedServices;
  final String farmhouseId;
  final List<Map<String, dynamic>> timeSlots;
  final double pricePerSeat;
  final int numberOfPersons;
  final Map<String, dynamic> farmhouseData;

  const QuantityAndDateFarmhouseScreen({
    Key? key,
    required this.selectedServices,
    required this.farmhouseId,
    required this.timeSlots,
    required this.pricePerSeat,
    required this.numberOfPersons,
    required this.farmhouseData,
  }) : super(key: key);

  @override
  _QuantityAndDateFarmhouseScreenState createState() =>
      _QuantityAndDateFarmhouseScreenState();
}

class _QuantityAndDateFarmhouseScreenState
    extends State<QuantityAndDateFarmhouseScreen> {
  final Map<String, int> _quantities = {};
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    for (var service in widget.selectedServices) {
      _quantities[service['name']] = 1;
    }
  }

  void _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _selectedTimeSlot = null;
      });
    }
  }

  Future<void> _bookFarmhouse() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time slot')),
      );
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final bookingRef = FirebaseFirestore.instance.collection('FarmBookings');

      await bookingRef.add({
        'farmhouseId': widget.farmhouseId,
        'userId': user.uid, // Use the current user ID
        'date': dateStr,
        'timeSlot': _selectedTimeSlot,
        'numberOfPersons': widget.numberOfPersons,
        'services': widget.selectedServices
            .map((service) => {
                  'name': service['name'],
                  'quantity': _quantities[service['name']],
                  'price': service['price']
                })
            .toList(),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update time slot availability
      final slotQuery = await FirebaseFirestore.instance
          .collection('Farmhouses')
          .doc(widget.farmhouseId)
          .collection('timeSlots')
          .where('date', isEqualTo: dateStr)
          .where('startTime', isEqualTo: _selectedTimeSlot!.split(' - ')[0])
          .get();

      if (slotQuery.docs.isNotEmpty) {
        await slotQuery.docs.first.reference.update({'isBooked': true});
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AvailabilityFarm(
            selectedServices: widget.selectedServices,
            quantities: _quantities,
            selectedDate: _selectedDate!,
            selectedTimeSlot: _selectedTimeSlot!,
            pricePerSeat: widget.pricePerSeat,
            numberOfPersons: widget.numberOfPersons,
            farmhouseId: widget.farmhouseId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Booking Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price per Seat: \$${widget.pricePerSeat.toStringAsFixed(2)}'),
            const SizedBox(height: 20),
            const Text('Selected Services:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...widget.selectedServices.map((service) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(service['name']),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => setState(() {
                                if (_quantities[service['name']]! > 1) {
                                  _quantities[service['name']] =
                                      _quantities[service['name']]! - 1;
                                }
                              }),
                            ),
                            Text('${_quantities[service['name']]}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => setState(() {
                                _quantities[service['name']] =
                                    _quantities[service['name']]! + 1;
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectDate,
              child: Text(_selectedDate == null
                  ? 'Select Date'
                  : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
            ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 20),
              const Text('Available Time Slots:',
                  style: TextStyle(fontSize: 16)),
              ...widget.timeSlots.map((slot) => RadioListTile<String>(
                    title: Text('${slot['startTime']} - ${slot['endTime']}'),
                    value: '${slot['startTime']} - ${slot['endTime']}',
                    groupValue: _selectedTimeSlot,
                    onChanged: (value) =>
                        setState(() => _selectedTimeSlot = value),
                  )),
            ],
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _bookFarmhouse,
                child: const Text('Confirm Booking'),
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
