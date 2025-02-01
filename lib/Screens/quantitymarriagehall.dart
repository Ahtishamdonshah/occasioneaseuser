import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:occasioneaseuser/Screens/availabilitymarriagehall.dart';

class QuantityAndDateMarriageHallScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedServices;
  final String marriageHallId;
  final List<Map<String, dynamic>> timeSlots;
  final double pricePerSeat;
  final int numberOfPersons;
  final Map<String, dynamic> hallData;

  const QuantityAndDateMarriageHallScreen({
    Key? key,
    required this.selectedServices,
    required this.marriageHallId,
    required this.timeSlots,
    required this.pricePerSeat,
    required this.numberOfPersons,
    required this.hallData,
  }) : super(key: key);

  @override
  _QuantityAndDateMarriageHallState createState() =>
      _QuantityAndDateMarriageHallState();
}

class _QuantityAndDateMarriageHallState
    extends State<QuantityAndDateMarriageHallScreen> {
  late Map<String, int> _quantities;
  DateTime? _selectedDate;
  Map<String, dynamic>? _selectedTimeSlot;
  List<String> _bookedSlotIds = [];

  @override
  void initState() {
    super.initState();
    _quantities = {
      for (var service in widget.selectedServices) service['name']: 1
    };
  }

  Future<void> _fetchBookedSlots(DateTime date) async {
    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('marriageHallId', isEqualTo: widget.marriageHallId)
          .where('date', isEqualTo: formattedDate)
          .get();

      List<String> bookedSlotIds = [];
      for (var doc in querySnapshot.docs) {
        bookedSlotIds.add(doc['timeSlotId'] as String);
      }

      setState(() {
        _bookedSlotIds = bookedSlotIds;
      });
    } catch (e) {
      print('Error fetching booked slots: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking availability')),
      );
    }
  }

  void _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _selectedTimeSlot = null;
      });
      await _fetchBookedSlots(pickedDate);
    }
  }

  Future<bool> _checkAvailability(
      DateTime date, Map<String, dynamic> timeSlot) async {
    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('marriageHallId', isEqualTo: widget.marriageHallId)
          .where('date', isEqualTo: formattedDate)
          .where('timeSlotId', isEqualTo: timeSlot['id'])
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking availability: $e');
      return false;
    }
  }

  void _proceedToBooking() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select date and time slot')),
      );
      return;
    }

    bool isAvailable =
        await _checkAvailability(_selectedDate!, _selectedTimeSlot!);
    if (!isAvailable) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Slot Booked'),
          content: Text('This slot is already booked. Please choose another.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvailabilityMarriageHall(
          selectedServices: widget.selectedServices,
          quantities: _quantities,
          selectedDate: _selectedDate!,
          selectedTimeSlot: _selectedTimeSlot!,
          pricePerSeat: widget.pricePerSeat,
          numberOfPersons: widget.numberOfPersons,
          marriageHallId: widget.marriageHallId,
          hallData: widget.hallData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Booking Details')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoTile(
                'Number of Persons', widget.numberOfPersons.toString()),
            Divider(),
            _buildServiceSelection(),
            SizedBox(height: 20),
            _buildDatePicker(),
            if (_selectedDate != null) _buildTimeSlots(),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _proceedToBooking,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  child: Text('Check Availability & Book'),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildServiceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selected Services:', style: TextStyle(fontSize: 18)),
        SizedBox(height: 10),
        ...widget.selectedServices.map((service) => Card(
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service['name'],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('\$${service['price']} per unit',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    _buildQuantityControls(service['name']),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildQuantityControls(String serviceName) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.remove_circle_outline),
          onPressed: () => setState(() {
            if (_quantities[serviceName]! > 1) {
              _quantities[serviceName] = _quantities[serviceName]! - 1;
            }
          }),
        ),
        Text('${_quantities[serviceName]}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        IconButton(
          icon: Icon(Icons.add_circle_outline),
          onPressed: () => setState(() {
            _quantities[serviceName] = _quantities[serviceName]! + 1;
          }),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Center(
      child: ElevatedButton(
        onPressed: _selectDate,
        child: Text(_selectedDate == null
            ? 'Select Date'
            : 'Selected: ${DateFormat.yMd().format(_selectedDate!)}'),
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text('Available Time Slots:', style: TextStyle(fontSize: 18)),
        ...widget.timeSlots.map((slot) {
          bool isBooked = _bookedSlotIds.contains(slot['id']);
          return RadioListTile<Map<String, dynamic>>(
            title: Text('${slot['startTime']} - ${slot['endTime']}'),
            value: slot,
            groupValue: _selectedTimeSlot,
            onChanged: isBooked
                ? null
                : (value) => setState(() => _selectedTimeSlot = value),
            subtitle: isBooked
                ? Text('Booked', style: TextStyle(color: Colors.red))
                : null,
            activeColor:
                isBooked ? Colors.grey : Theme.of(context).primaryColor,
          );
        }),
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (idx) =>
          Navigator.pushNamed(context, idx == 1 ? '/favorites' : '/profile'),
    );
  }
}
