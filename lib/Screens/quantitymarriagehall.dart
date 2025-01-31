import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _quantities = {
      for (var service in widget.selectedServices) service['name']: 1
    };
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
    }
  }

  void _proceedToBooking() {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select date and time slot')),
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
      body: Padding(
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
        ...widget.timeSlots.map((slot) => RadioListTile<Map<String, dynamic>>(
              title: Text('${slot['startTime']} - ${slot['endTime']}'),
              value: slot,
              groupValue: _selectedTimeSlot,
              onChanged: (value) => setState(() => _selectedTimeSlot = value),
            )),
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
