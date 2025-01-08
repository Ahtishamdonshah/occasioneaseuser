import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
                Column(
                  children: widget.timeSlots.map((slot) {
                    return RadioListTile<String>(
                      title: Text(slot),
                      value: slot,
                      groupValue: _selectedTimeSlot,
                      onChanged: (value) {
                        setState(() {
                          _selectedTimeSlot = value;
                        });
                      },
                    );
                  }).toList(),
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
}
