import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class availabilityfarm extends StatefulWidget {
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, int> quantities;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final double pricePerSeat; // Add pricePerSeat to the constructor

  const availabilityfarm({
    Key? key,
    required this.selectedServices,
    required this.quantities,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.pricePerSeat,
    required List<Map<String, dynamic>> services,
    required DateTime date,
    required String timeSlot, // Receive pricePerSeat
  }) : super(key: key);

  @override
  _availabilityfarmState createState() => _availabilityfarmState();
}

class _availabilityfarmState extends State<availabilityfarm> {
  bool _isLoading = true;
  String? _parlorId;
  double _totalPrice = 0.0;
  late String _userId; // Store the current user's ID

  @override
  void initState() {
    super.initState();
    _getUserId(); // Fetch the current user ID
    _calculateTotalPrice();
  }

  // Fetch current user ID using Firebase Authentication
  Future<void> _getUserId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userId = user.uid; // Store the current user's UID
        _fetchParlorIdAndTimeSlots();
      } else {
        // Handle case when no user is logged in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is logged in.')),
        );
      }
    } catch (e) {
      print('Error fetching user ID: $e');
    }
  }

  // Fetch ParlorId and time slots
  Future<void> _fetchParlorIdAndTimeSlots() async {
    setState(() => _isLoading = true);

    try {
      // Fetch user data from 'Users' collection based on the current userId
      final userSnapshot = await FirebaseFirestore.instance
          .collection('Beauty Parlors')
          .doc(_userId) // Fetch user document using current logged-in userId
          .get();

      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>;

        // Extract parlorId from user document (assuming it's stored in user document)
        _parlorId = userData[
            'parlorId']; // Assuming 'parlorId' field exists in user document
        print('Fetched parlorId: $_parlorId');

        if (_parlorId != null) {
          // Now fetch time slots for the fetched parlorId
          final parlorSnapshot = await FirebaseFirestore.instance
              .collection('Beauty Parlors')
              .doc(_parlorId) // Using the fetched parlorId
              .get();

          if (parlorSnapshot.exists) {
            final parlorData = parlorSnapshot.data() as Map<String, dynamic>;
            final timeSlotsData = parlorData['timeslot'] ?? [];
            print('Time Slots Data: $timeSlotsData');

            // Validate the time slots data type
            if (timeSlotsData is List) {}
          } else {
            print('No parlor found with ID: $_parlorId');
          }
        }
      } else {
        print('No user found with ID: $_userId');
      }
    } catch (e) {
      print('Error fetching time slots: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching time slots: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  // Calculate total price based on selected services, quantities, and pricePerSeat
  void _calculateTotalPrice() {
    double total = 0.0;
    for (var service in widget.selectedServices) {
      final price = service['price'] ?? 0.0;
      final quantity = widget.quantities[service['name']] ?? 1;
      total += price * quantity;
    }
    // Add pricePerSeat to the total price calculation
    total += widget.pricePerSeat *
        widget.quantities
            .length; // Example: multiplying by number of rooms selected
    setState(() {
      _totalPrice = total;
    });
  }

  // Book Appointment
  Future<void> _bookAppointment() async {
    try {
      await FirebaseFirestore.instance.collection('Bookingfarm').add({
        'parlorId': _parlorId,
        'userId': _userId, // Using the current user ID
        'services': widget.selectedServices.map((service) {
          return {
            'name': service['name'],
            'quantity': widget.quantities[service['name']],
            'price': service['price'],
          };
        }).toList(),
        'date': widget.selectedDate,
        'timeSlot': widget.selectedTimeSlot,
        'totalPrice': _totalPrice,
        'status': 'Pending', // You can adjust the status if needed
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment successfully booked!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking appointment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Summary'),
      ),
      body: Column(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListView(
                    children: [
                      // Price Per Seat and Total Cost
                      const SizedBox(height: 16),
                      Text(
                        'Price per Seat: \$${widget.pricePerSeat}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      // Display services, quantities, and total price
                      ...widget.selectedServices.map((service) {
                        final quantity =
                            widget.quantities[service['name']] ?? 1;
                        return ListTile(
                          title: Text(service['name']),
                          subtitle: Text('Quantity: $quantity'),
                          trailing: Text('Price: \$${service['price']}'),
                        );
                      }).toList(),

                      // Display selected date and time slot
                      ListTile(
                        title: const Text('Date'),
                        subtitle: Text('${widget.selectedDate}'),
                      ),
                      ListTile(
                        title: const Text('Time Slot'),
                        subtitle: Text(widget.selectedTimeSlot),
                      ),

                      // Display total price
                      ListTile(
                        title: const Text('Total Price'),
                        subtitle: Text('\$$_totalPrice'),
                      ),

                      // Booking Button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: _bookAppointment,
                          child: const Text('Book Now'),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
