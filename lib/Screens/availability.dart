import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class availability extends StatefulWidget {
  final String userId;

  const availability({Key? key, required this.userId}) : super(key: key);

  @override
  _availabilityState createState() => _availabilityState();
}

class _availabilityState extends State<availability> {
  List<Map<String, dynamic>> _timeSlots = [];
  bool _isLoading = true;
  String? _parlorId;

  @override
  void initState() {
    super.initState();
    _fetchParlorIdAndTimeSlots();
  }

  // Fetch ParlorId from user document, then fetch time slots
  Future<void> _fetchParlorIdAndTimeSlots() async {
    setState(() => _isLoading = true);

    try {
      // Fetch user data from 'Users' collection based on userId
      final userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId) // Fetch user document using userId
          .get();

      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>;

        // Extract parlorId from user document (assuming it's stored in the user's document)
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
            final timeSlotsData = parlorData['timeSlots'] ?? [];
            print('Time Slots Data: $timeSlotsData');

            // Validate the time slots data type
            if (timeSlotsData is List) {
              _timeSlots = timeSlotsData.map((slot) {
                return Map<String, dynamic>.from(slot);
              }).toList();
            }
          } else {
            print('No parlor found with ID: $_parlorId');
            _timeSlots = [];
          }
        }
      } else {
        print('No user found with ID: ${widget.userId}');
        _timeSlots = [];
      }
    } catch (e) {
      print('Error fetching time slots: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching time slots: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability'),
      ),
      body: Column(
        children: [
          // Loading Indicator or Time Slots List
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _timeSlots.isEmpty
                  ? const Center(
                      child: Text('No time slots available for this parlor.'))
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _timeSlots.length,
                        itemBuilder: (context, index) {
                          final slot = _timeSlots[index];
                          final startTime = slot['startTime'] ?? 'N/A';
                          final endTime = slot['endTime'] ?? 'N/A';
                          final capacity = slot['capacity'] ?? 'Unknown';

                          return ListTile(
                            title: Text('From: $startTime To: $endTime'),
                            subtitle: Text('Capacity: $capacity'),
                            trailing: ElevatedButton(
                              onPressed: () {
                                // Handle Booking Logic
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Slot from $startTime to $endTime booked'),
                                  ),
                                );
                              },
                              child: const Text('Book'),
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}
