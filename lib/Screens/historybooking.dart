import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingHistoryScreen extends StatelessWidget {
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
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

  bool _isPastBooking(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return false;

    final bookingDate = _getBookingDate(data);
    if (bookingDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return bookingDate.isBefore(today);
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
        title: const Text('Booking History'),
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
                'No historical bookings found',
                style: TextStyle(color: Colors.blueGrey),
              ),
            );
          }

          final allBookings = snapshot.data!
              .expand((qs) => qs.docs.cast<QueryDocumentSnapshot>())
              .where((doc) => _isPastBooking(doc))
              .toList();

          if (allBookings.isEmpty) {
            return const Center(
              child: Text(
                'No past bookings found',
                style: TextStyle(color: Colors.blueGrey),
              ),
            );
          }

          allBookings.sort((a, b) {
            final aDate = _getBookingDate(a.data() as Map<String, dynamic>);
            final bDate = _getBookingDate(b.data() as Map<String, dynamic>);
            return (bDate ?? DateTime.now()).compareTo(aDate ?? DateTime.now());
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
                  ...bookings.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final vendorId = data['vendorId'] as String? ?? '';
                    return _buildBookingCard(
                      data,
                      doc.reference.parent.id,
                      doc.id,
                      vendorId,
                    );
                  }),
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

  Widget _buildBookingCard(Map<String, dynamic> booking, String collectionName,
      String bookingId, String vendorId) {
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
              Text('Booking ID: $bookingId'),
              _buildDetailRow(
                  'Date',
                  bookingDate != null
                      ? displayDateFormat.format(bookingDate)
                      : 'N/A'),
              _buildTotalPrice(booking['totalPrice'] ?? 0),
              const SizedBox(height: 16),
              if (vendorId.isNotEmpty) _buildRatingSection(bookingId, vendorId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalPrice(dynamic totalPrice) {
    return _buildDetailRow('Total Price', '\$${totalPrice.toString()}');
  }

  Widget _buildRatingSection(String bookingId, String vendorId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('ratings')
          .where('userId', isEqualTo: currentUserId)
          .where('vendorId', isEqualTo: vendorId)
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final rating = snapshot.data!.docs.first['rating'];
          return Text('Your Rating: $rating ★',
              style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 16));
        }
        return _RatingInput(
            bookingId: bookingId, vendorId: vendorId, userId: currentUserId);
      },
    );
  }
}

class _RatingInput extends StatelessWidget {
  final String bookingId, vendorId, userId;
  const _RatingInput(
      {required this.bookingId, required this.vendorId, required this.userId});

  Future<void> _submitRating(int rating) async {
    await FirebaseFirestore.instance.collection('ratings').add({
      'userId': userId,
      'vendorId': vendorId,
      'bookingId': bookingId,
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _submitRating(5),
      child: const Text('Rate 5 Stars'),
    );
  }
}
