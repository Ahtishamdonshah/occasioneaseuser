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

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _selectedTimeSlot = null;
      });
    }
  }

  void _proceedToBooking() {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date and time slot')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => availabilitymarriagehall(
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
      appBar: AppBar(
        title: Text('Booking Details'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Number of Persons: ${widget.numberOfPersons}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),

            // Services with Quantity Selectors
            Text('Selected Services:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ...widget.selectedServices.map((service) => Card(
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(service['name'],
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('\$${service['price']} per unit',
                                style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: Colors.blue),
                              onPressed: () => setState(() {
                                if (_quantities[service['name']]! > 1) {
                                  _quantities[service['name']] =
                                      _quantities[service['name']]! - 1;
                                }
                              }),
                            ),
                            Text('${_quantities[service['name']]}',
                                style: TextStyle(fontSize: 16)),
                            IconButton(
                              icon: Icon(Icons.add, color: Colors.blue),
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

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectDate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              child: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : 'Selected: ${DateFormat.yMd().format(_selectedDate!)}',
                style: TextStyle(fontSize: 16),
              ),
            ),

            if (_selectedDate != null) ...[
              SizedBox(height: 20),
              Text('Available Time Slots:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...widget.timeSlots.map((slot) => Card(
                    child: RadioListTile<Map<String, dynamic>>(
                      title: Text('${slot['startTime']} - ${slot['endTime']}'),
                      subtitle: Text('Max events: ${slot['maxEvents']}'),
                      value: slot,
                      groupValue: _selectedTimeSlot,
                      onChanged: (value) =>
                          setState(() => _selectedTimeSlot = value),
                    ),
                  )),
            ],

            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _proceedToBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                ),
                child: Text('Check Availability & Book',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
