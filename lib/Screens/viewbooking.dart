import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatelessWidget {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat displayDateFormat = DateFormat('MMM dd, yyyy');

  Future<List<QuerySnapshot>> _fetchBookings() async {
    if (currentUserId.isEmpty) return [];

    final collections = [
      'BeautyParlorBookings',
      'SaloonBookings',
      'PhotographerBookings',
      'CateringBookings',
      'FarmhouseBookings',
      'MarriageHallBookings'
    ];

    final futures = collections
        .map((collection) => FirebaseFirestore.instance
            .collection(collection)
            .where('userId', isEqualTo: currentUserId)
            .get())
        .toList();

    return Future.wait(futures);
  }

  DateTime? _getBookingDate(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] as Timestamp?;
    if (timestamp != null) return timestamp.toDate();

    final dateStr = data['date'] as String?;
    if (dateStr != null) {
      try {
        return dateFormat.parse(dateStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  bool _isUpcomingBooking(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return false;

    final bookingDate = _getBookingDate(data);
    if (bookingDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return bookingDate.isAfter(today.subtract(const Duration(seconds: 1)));
  }

  Map<String, List<QueryDocumentSnapshot>> groupBookingsByDate(
      List<QueryDocumentSnapshot> bookings) {
    final grouped = <String, List<QueryDocumentSnapshot>>{};
    for (final doc in bookings) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      final bookingDate = _getBookingDate(data);
      if (bookingDate == null) continue;

      final dateKey = dateFormat.format(bookingDate);
      grouped.putIfAbsent(dateKey, () => []).add(doc);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Bookings'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<QuerySnapshot>>(
        future: _fetchBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No bookings found',
                style: TextStyle(color: Colors.blueGrey),
              ),
            );
          }

          final allBookings = snapshot.data!
              .expand((qs) => qs.docs.cast<QueryDocumentSnapshot>())
              .where((doc) => _isUpcomingBooking(doc))
              .toList();

          if (allBookings.isEmpty) {
            return const Center(
              child: Text(
                'No upcoming bookings found',
                style: TextStyle(color: Colors.blueGrey),
              ),
            );
          }

          allBookings.sort((a, b) {
            final aDate = _getBookingDate(a.data() as Map<String, dynamic>);
            final bDate = _getBookingDate(b.data() as Map<String, dynamic>);
            return (aDate ?? DateTime.now()).compareTo(bDate ?? DateTime.now());
          });

          final groupedBookings = groupBookingsByDate(allBookings);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: groupedBookings.length,
            itemBuilder: (context, index) {
              final dateKey = groupedBookings.keys.elementAt(index);
              final bookings = groupedBookings[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(dateKey),
                  ...bookings.map((doc) => _buildBookingCard(
                        doc.data() as Map<String, dynamic>,
                        doc.reference.parent.id,
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(String dateKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        displayDateFormat.format(DateTime.parse(dateKey)),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  Widget _buildBookingCard(
      Map<String, dynamic> booking, String collectionName) {
    final bookingDate = _getBookingDate(booking);
    if (bookingDate == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          border: const Border(left: BorderSide(color: Colors.blue, width: 4)),
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBookingHeader(collectionName, booking['status']),
              const SizedBox(height: 12),
              _buildDetailRow('Date', displayDateFormat.format(bookingDate)),
              if (booking['timeSlot'] != null)
                _buildDetailRow('Time Slot', booking['timeSlot']),
              _buildTotalPrice(booking['totalPrice']),
              _buildServiceList(booking['services']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingHeader(String collectionName, String? status) {
    final categoryName = collectionName.replaceAll('Bookings', '');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$categoryName Booking',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
        Chip(
          label: Text(
            status ?? 'Pending',
            style: TextStyle(color: Colors.blue[900]),
          ),
          backgroundColor: _getStatusColor(status),
        ),
      ],
    );
  }

  Widget _buildServiceList(dynamic services) {
    if (services == null || !(services is List)) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('Services:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...List<Widget>.from(services.map((service) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child:
                        Text(service['name']?.toString() ?? 'Unknown Service'),
                  ),
                  Text('${service['quantity']} x ₹${service['price']}')
                ],
              ),
            ))),
      ],
    );
  }

  Widget _buildTotalPrice(dynamic totalPrice) {
    return _buildDetailRow(
      'Total Price',
      '₹${(totalPrice is num ? totalPrice.toStringAsFixed(2) : '0.00')}',
      isTotal: true,
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.blue[800],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.blue[800],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'booked':
        return Colors.green[100]!;
      case 'cancelled':
        return Colors.red[100]!;
      default:
        return Colors.orange[100]!;
    }
  }
}
