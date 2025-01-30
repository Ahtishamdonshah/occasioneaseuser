import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class availabilitymarriagehall extends StatefulWidget {
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, int> quantities;
  final DateTime selectedDate;
  final Map<String, dynamic> selectedTimeSlot;
  final double pricePerSeat;
  final int numberOfPersons;
  final String marriageHallId;
  final Map<String, dynamic> hallData;

  const availabilitymarriagehall({
    Key? key,
    required this.selectedServices,
    required this.quantities,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.pricePerSeat,
    required this.numberOfPersons,
    required this.marriageHallId,
    required this.hallData,
  }) : super(key: key);

  @override
  _availabilitymarriagehallState createState() =>
      _availabilitymarriagehallState();
}

class _availabilitymarriagehallState extends State<availabilitymarriagehall> {
  late double _totalPrice;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _calculateTotalPrice();
  }

  void _calculateTotalPrice() {
    double basePrice = widget.numberOfPersons * widget.pricePerSeat;
    double servicesTotal = widget.selectedServices.fold(0.0, (sum, service) {
      return sum + (service['price'] * widget.quantities[service['name']]!);
    });
    _totalPrice = basePrice + servicesTotal;
  }

  Future<void> _checkAvailability() async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

      final bookings = await FirebaseFirestore.instance
          .collection('MarriageHallBookings')
          .where('marriageHallId', isEqualTo: widget.marriageHallId)
          .where('date', isEqualTo: dateStr)
          .where('timeSlot.startTime',
              isEqualTo: widget.selectedTimeSlot['startTime'])
          .get();

      setState(() {
        _isAvailable =
            bookings.docs.length < widget.selectedTimeSlot['maxEvents'];
      });

      if (_isAvailable) {
        await FirebaseFirestore.instance
            .collection('MarriageHallBookings')
            .add({
          'marriageHallId': widget.marriageHallId,
          'date': dateStr,
          'timeSlot': widget.selectedTimeSlot,
          'services': widget.selectedServices
              .map((service) => {
                    'name': service['name'],
                    'quantity': widget.quantities[service['name']],
                    'price': service['price']
                  })
              .toList(),
          'totalPrice': _totalPrice,
          'numberOfPersons': widget.numberOfPersons,
          'status': 'Booked',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isAvailable
                ? 'Slot is available and booked!'
                : 'Slot is fully booked!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: _isAvailable ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking availability')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Availability Check', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking Summary',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    Divider(),
                    Text(
                        'Date: ${DateFormat.yMd().format(widget.selectedDate)}',
                        style: TextStyle(fontSize: 16)),
                    Text(
                        'Time: ${widget.selectedTimeSlot['startTime']} - ${widget.selectedTimeSlot['endTime']}',
                        style: TextStyle(fontSize: 16)),
                    Text('Persons: ${widget.numberOfPersons}',
                        style: TextStyle(fontSize: 16)),
                    Text(
                        'Base Price: \$${(widget.numberOfPersons * widget.pricePerSeat).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16)),
                    SizedBox(height: 10),
                    ...widget.selectedServices.map((service) => ListTile(
                          title: Text(service['name'],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700)),
                          trailing: Text(
                              '\$${(service['price'] * widget.quantities[service['name']]!).toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.blue.shade900)),
                          subtitle: Text(
                              'Quantity: ${widget.quantities[service['name']]}'),
                        )),
                    Divider(),
                    Text('Total Price: \$${_totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkAvailability,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text('Check Availability',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
