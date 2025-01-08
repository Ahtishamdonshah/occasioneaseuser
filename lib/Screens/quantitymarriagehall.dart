import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:occasioneaseuser/Screens/availabilityfarm.dart';

class QuantityAndDateMarriageHallScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedServices;
  final String marriageHallId;
  final List<String> timeSlots;
  final double pricePerSeat;

  const QuantityAndDateMarriageHallScreen({
    Key? key,
    required this.selectedServices,
    required this.marriageHallId,
    required this.timeSlots,
    required this.pricePerSeat,
    required String hallId,
    required Map<String, dynamic> hallData,
    required DateTime selectedDate,
    required String selectedTimeSlot,
  }) : super(key: key);

  @override
  _QuantityAndDateMarriageHallScreenState createState() =>
      _QuantityAndDateMarriageHallScreenState();
}

class _QuantityAndDateMarriageHallScreenState
    extends State<QuantityAndDateMarriageHallScreen> {
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
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _selectedTimeSlot = null;
      });
    }
  }

  Future<void> _bookMarriageHall() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date and time slot'),
        ),
      );
      return;
    }

    try {
      // Add booking details to Firestore
      await FirebaseFirestore.instance.collection('MarriageHallBookings').add({
        'marriageHallId': widget.marriageHallId,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'timeSlot': _selectedTimeSlot,
        'services': widget.selectedServices
            .map((service) => {
                  'name': service['name'],
                  'quantity': _quantities[service['name']],
                  'price': service['price']
                })
            .toList(),
        'status': 'Pending',
      });

      // Update time slot as booked
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final timeSlotDoc = await FirebaseFirestore.instance
          .collection('MarriageHalls')
          .doc(widget.marriageHallId)
          .collection('timeSlots')
          .where('date', isEqualTo: dateStr)
          .where('startTime', isEqualTo: _selectedTimeSlot!.split(' - ')[0])
          .get();

      if (timeSlotDoc.docs.isNotEmpty) {
        await timeSlotDoc.docs.first.reference.update({'isBooked': true});
      }

      // Navigate to the AvailabilityPage with selected data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => availabilityfarm(
            selectedServices: widget.selectedServices,
            quantities: _quantities,
            selectedDate: _selectedDate!,
            selectedTimeSlot: _selectedTimeSlot!,
            pricePerSeat: widget.pricePerSeat,
            marriageHallId: widget.marriageHallId,
            farmId: widget
                .marriageHallId, // Assuming farmId is the same as marriageHallId
            timeSlot: _selectedTimeSlot!,
          ),
        ),
      );
    } catch (e) {
      print('Error booking marriage hall: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to book marriage hall'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marriage Hall Booking Details"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price Per Seat
              Text(
                'Price per Seat: \$${widget.pricePerSeat.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Selected Services
              const Text(
                'Selected Services:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...widget.selectedServices.map((service) {
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
              }),

              const SizedBox(height: 16),

              // Date Selection
              const Text(
                'Select Date:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _selectDate,
                child: Text(_selectedDate == null
                    ? 'Choose Date'
                    : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
              ),
              const SizedBox(height: 16),

              // Time Slot Selection
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

              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: _bookMarriageHall,
                  child: const Text('Book Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
