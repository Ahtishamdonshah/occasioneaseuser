import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:occasioneaseuser/Screens/availabilityfarm.dart';
// Import AvailabilityPage

class quantityanddateFarmhouseScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedRooms;
  final String farmhouseId;
  final List<String> timeSlots;
  final List<double> roomPrices;
  final double pricePerSeat; // Add this field to the constructor

  const quantityanddateFarmhouseScreen({
    Key? key,
    required this.selectedRooms,
    required this.farmhouseId,
    required this.timeSlots,
    required this.roomPrices,
    required this.pricePerSeat,
    required double farmhousePrice,
    required List<Map<String, dynamic>>
        selectedServices, // Pass the pricePerSeat here
  }) : super(key: key);

  @override
  _quantityanddateFarmhouseScreenState createState() =>
      _quantityanddateFarmhouseScreenState();
}

class _quantityanddateFarmhouseScreenState
    extends State<quantityanddateFarmhouseScreen> {
  final Map<String, int> _quantities = {};
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    for (var room in widget.selectedRooms) {
      _quantities[room['name']] = 1;
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

  Future<void> _bookFarmhouse() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date and time slot'),
        ),
      );
      return;
    }

    try {
      // Add the booking details to Firestore
      await FirebaseFirestore.instance.collection('FarmhouseBookings').add({
        'farmhouseId': widget.farmhouseId,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'timeSlot': _selectedTimeSlot,
        'rooms': widget.selectedRooms
            .map((room) => {
                  'name': room['name'],
                  'quantity': _quantities[room['name']],
                  'price': room['price']
                })
            .toList(),
        'status': 'Pending',
      });

      // Update the time slot as booked
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final timeSlotDoc = await FirebaseFirestore.instance
          .collection('Farmhouses')
          .doc(widget.farmhouseId)
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
            selectedServices: widget.selectedRooms, // List of selected rooms
            quantities: _quantities, // Map of room name to quantity
            selectedDate: _selectedDate!, // Selected date
            selectedTimeSlot: _selectedTimeSlot!, // Selected time slot
            // services: widget.selectedRooms, // Same rooms as before
            // date: _selectedDate!, // Same date as before
            timeSlot: _selectedTimeSlot!, // Selected time slot
            pricePerSeat: widget.pricePerSeat, // Pass pricePerSeat here
            farmId: widget.farmhouseId, // Add the required farmId parameter
            marriageHallId:
                widget.farmhouseId, // Add the required marriageHallId parameter
          ),
        ),
      );
    } catch (e) {
      print('Error booking farmhouse: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to book farmhouse'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Farmhouse Booking Details"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price Per Seat and Total Cost
              const SizedBox(height: 16),
              Text(
                'Price per Seat: \$${widget.pricePerSeat}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Selected Rooms: ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...widget.selectedRooms.map((room) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room['name'],
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Price: \$${room['price']}'),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    setState(() {
                                      if (_quantities[room['name']]! > 1) {
                                        _quantities[room['name']] =
                                            _quantities[room['name']]! - 1;
                                      }
                                    });
                                  },
                                ),
                                Text('${_quantities[room['name']]}'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      _quantities[room['name']] =
                                          _quantities[room['name']]! + 1;
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
                'Select Date: ',
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

              // Time Slot Selection
              if (_selectedDate != null) ...[
                const Text(
                  'Select Time Slot: ',
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
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _bookFarmhouse,
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
