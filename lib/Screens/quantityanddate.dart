import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class quantityanddate extends StatefulWidget {
  final List<Map<String, dynamic>> selectedSubservices;
  final String parlorId;

  const quantityanddate({
    Key? key,
    required this.selectedSubservices,
    required this.parlorId,
  }) : super(key: key);

  @override
  _quantityanddateState createState() => _quantityanddateState();
}

class _quantityanddateState extends State<quantityanddate> {
  final Map<String, int> _quantities = {};
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    for (var service in widget.selectedSubservices) {
      _quantities[service['name']] = 1; // Default quantity is 1
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Details"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selected Services:',
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
              }),
              const SizedBox(height: 16),

              // Date Selection
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

              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a date'),
                        ),
                      );
                      return;
                    }

                    // Navigate to the availability page with the parlor ID and selected date
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AvailabilityPage(
                          parlorId: widget.parlorId,
                          selectedDate: _selectedDate!,
                        ),
                      ),
                    );
                  },
                  child: const Text('Check Availability'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AvailabilityPage extends StatelessWidget {
  final String parlorId;
  final DateTime selectedDate;

  const AvailabilityPage({
    Key? key,
    required this.parlorId,
    required this.selectedDate,
  }) : super(key: key);

  Future<List<String>> _fetchTimeSlots(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final snapshot = await FirebaseFirestore.instance
        .collection('Beauty Parlors')
        .doc(parlorId)
        .collection('timeSlots')
        .where('date', isEqualTo: dateStr)
        .get();

    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs
        .map((doc) => '${doc['startTime']} - ${doc['endTime']}')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Time Slots"),
      ),
      body: FutureBuilder<List<String>>(
        future: _fetchTimeSlots(selectedDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data!.isEmpty) {
            return const Center(child: Text('No time slots available.'));
          }

          final timeSlots = snapshot.data!;

          return ListView.builder(
            itemCount: timeSlots.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(timeSlots[index]),
              );
            },
          );
        },
      ),
    );
  }
}
