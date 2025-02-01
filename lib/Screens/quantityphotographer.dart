import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:occasioneaseuser/Screens/availabilityphotographer.dart';
import 'package:occasioneaseuser/Screens/viewbooking.dart';
import 'home_screem.dart';
import 'heart.dart';

class QuantityPhotographer extends StatefulWidget {
  final List<Map<String, dynamic>> selectedSubservices;
  final String photographerId;
  final List<Map<String, dynamic>> timeSlots;

  const QuantityPhotographer({
    Key? key,
    required this.selectedSubservices,
    required this.photographerId,
    required this.timeSlots,
  }) : super(key: key);

  @override
  _QuantityPhotographerState createState() => _QuantityPhotographerState();
}

class _QuantityPhotographerState extends State<QuantityPhotographer> {
  final Map<String, int> _quantities = {};
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  Map<String, int> _availableCapacities = {};
  bool _isLoading = false;
  int _selectedIndex = 0;

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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateAvailableCapacities(DateTime selectedDate) async {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final bookingsQuery = await FirebaseFirestore.instance
        .collection('PhotographerBookings')
        .where('photographerId', isEqualTo: widget.photographerId)
        .where('date', isEqualTo: selectedDateStr)
        .get();

    final Map<String, int> bookedSlots = {};
    for (var bookingDoc in bookingsQuery.docs) {
      final bookingData = bookingDoc.data();
      final timeSlot = bookingData['timeSlot'];
      if (timeSlot != null) {
        bookedSlots.update(timeSlot, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    final Map<String, int> availableCapacities = {};
    for (var timeSlot in widget.timeSlots) {
      final startTime = timeSlot['startTime'] ?? '';
      final endTime = timeSlot['endTime'] ?? '';
      final capacity = timeSlot['capacity'] ?? 0;
      final timeSlotString = '$startTime - $endTime';
      availableCapacities[timeSlotString] =
          capacity - (bookedSlots[timeSlotString] ?? 0);
    }

    setState(() => _availableCapacities = availableCapacities);
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    if ((_availableCapacities[_selectedTimeSlot!] ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time slot unavailable')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvailabilityPhotographer(
          selectedServices: widget.selectedSubservices,
          quantities: _quantities,
          selectedDate: _selectedDate!,
          selectedTimeSlot: _selectedTimeSlot!,
          photographerId: widget.photographerId,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (_selectedIndex == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else if (_selectedIndex == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HeartScreen()),
      );
    } else if (_selectedIndex == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BookingsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Details"),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Services:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            ...widget.selectedSubservices.map((service) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Price: RS ${service['price']}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            Text(
              'Select Date:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _selectDate,
              child: Text(
                _selectedDate == null
                    ? 'Choose Date'
                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
              ),
            ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 16),
              Text(
                'Select Time Slot:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: widget.timeSlots.map((timeSlot) {
                        final startTime = timeSlot['startTime'] ?? '';
                        final endTime = timeSlot['endTime'] ?? '';
                        final timeSlotString = '$startTime - $endTime';
                        final available =
                            _availableCapacities[timeSlotString] ?? 0;
                        final isAvailable = available > 0;

                        return RadioListTile<String>(
                          title: Text('$timeSlotString ($available available)'),
                          subtitle: !isAvailable
                              ? const Text(
                                  'Not available',
                                  style: TextStyle(color: Colors.red),
                                )
                              : null,
                          value: timeSlotString,
                          groupValue: _selectedTimeSlot,
                          onChanged: isAvailable
                              ? (value) =>
                                  setState(() => _selectedTimeSlot = value)
                              : null,
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _selectedTimeSlot != null &&
                          (_availableCapacities[_selectedTimeSlot!] ?? 0) > 0
                      ? _bookAppointment
                      : null,
                  child: const Text('Book Now'),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.blue[700],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Heart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Bookings',
          ),
        ],
      ),
    );
  }
}
