import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
      lastDate: DateTime.now().add(Duration(days: 30)),
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

    final Map<String, int> bookedQuantities = {};
    for (var bookingDoc in bookingsQuery.docs) {
      final bookingData = bookingDoc.data();
      final timeSlot = bookingData['timeSlot'];
      final services = bookingData['services'];
      if (timeSlot == null || services == null) continue;

      int totalQuantity =
          services.fold(0, (sum, service) => sum + (service['quantity'] ?? 0));
      bookedQuantities.update(timeSlot, (value) => value + totalQuantity,
          ifAbsent: () => totalQuantity);
    }

    final Map<String, int> availableCapacities = {};
    for (var timeSlot in widget.timeSlots) {
      final startTime = timeSlot['startTime'] ?? '';
      final endTime = timeSlot['endTime'] ?? '';
      final capacity = timeSlot['capacity'] ?? 0;
      final timeSlotString = '$startTime - $endTime';
      availableCapacities[timeSlotString] =
          capacity - (bookedQuantities[timeSlotString] ?? 0);
    }

    setState(() => _availableCapacities = availableCapacities);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Photographer Details")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selected Services:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...widget.selectedSubservices.map((service) => Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service['name'],
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Price: \$${service['price']}'),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () => setState(() {
                                    if (_quantities[service['name']]! > 1) {
                                      _quantities[service['name']] =
                                          _quantities[service['name']]! - 1;
                                    }
                                  }),
                                ),
                                Text('${_quantities[service['name']]}'),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () => setState(() =>
                                      _quantities[service['name']] =
                                          _quantities[service['name']]! + 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
            SizedBox(height: 16),
            Text('Select Date:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: _selectDate,
              child: Text(_selectedDate == null
                  ? 'Choose Date'
                  : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
            ),
            if (_selectedDate != null) ...[
              SizedBox(height: 16),
              Text('Select Time Slot:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _isLoading
                  ? CircularProgressIndicator()
                  : Column(
                      children: widget.timeSlots.map((timeSlot) {
                        final startTime = timeSlot['startTime'] ?? '';
                        final endTime = timeSlot['endTime'] ?? '';
                        final timeSlotString = '$startTime - $endTime';
                        final available =
                            _availableCapacities[timeSlotString] ?? 0;
                        return RadioListTile<String>(
                          title: Text('$timeSlotString ($available available)'),
                          value: timeSlotString,
                          groupValue: _selectedTimeSlot,
                          onChanged: available > 0
                              ? (value) =>
                                  setState(() => _selectedTimeSlot = value)
                              : null,
                        );
                      }).toList(),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
