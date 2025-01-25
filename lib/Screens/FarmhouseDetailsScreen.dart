import 'package:flutter/material.dart';
import 'package:occasioneaseuser/Screens/quantityanddatefarmhouse.dart';

class FarmhouseDetailsScreen extends StatefulWidget {
  final String farmhouseId;
  final Map<String, dynamic> farmhouseData;
  final List<String> timeSlots;

  const FarmhouseDetailsScreen({
    Key? key,
    required this.farmhouseId,
    required this.farmhouseData,
    required this.timeSlots,
  }) : super(key: key);

  @override
  _FarmhouseDetailsScreenState createState() => _FarmhouseDetailsScreenState();
}

class _FarmhouseDetailsScreenState extends State<FarmhouseDetailsScreen> {
  late List<bool> _selectedServices;

  @override
  void initState() {
    super.initState();
    _selectedServices = List.filled(
        widget.farmhouseData['additionalServices']?.length ?? 0, false);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images =
        List<String>.from(widget.farmhouseData['imageUrls'] ?? []);
    final String name = widget.farmhouseData['name'] ?? 'N/A';
    final String location = widget.farmhouseData['location'] ?? 'N/A';
    final double farmhousePrice = widget.farmhouseData['price'] ?? 0;
    final double pricePerSeat =
        widget.farmhouseData['pricePerSeat'] ?? 0; // Get pricePerSeat
    final List<dynamic> additionalServices =
        widget.farmhouseData['additionalServices'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              Container(
                height: 200,
                margin: const EdgeInsets.only(bottom: 16),
                child: PageView(
                  children: images
                      .map(
                        (url) => Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Text('Image not available')),
                        ),
                      )
                      .toList(),
                ),
              )
            else
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No images available'),
              )),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Location: $location',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                      'Price per Seat: \$${pricePerSeat.toStringAsFixed(2)}', // Display price per seat
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  const Text('Additional Services:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...List.generate(additionalServices.length, (index) {
                    final service = additionalServices[index];
                    return CheckboxListTile(
                      title: Text(service['name'] ?? 'N/A'),
                      subtitle: Text(
                          'Price: \$${(service['price'] ?? 0).toStringAsFixed(2)}'),
                      value: _selectedServices[index],
                      onChanged: (bool? value) {
                        setState(() {
                          _selectedServices[index] = value ?? false;
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        final selectedServices = <Map<String, dynamic>>[];

                        // Collect selected services
                        for (int i = 0; i < _selectedServices.length; i++) {
                          if (_selectedServices[i]) {
                            selectedServices.add(additionalServices[i]);
                          }
                        }

                        // Navigating to Quantity and Date Screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                quantityanddateFarmhouseScreen(
                              selectedRooms:
                                  selectedServices, // Assuming 'selectedServices' is the equivalent of selected rooms
                              farmhouseId: widget.farmhouseId,
                              timeSlots: widget.timeSlots,
                              roomPrices: [
                                farmhousePrice
                              ], // Wrap the farmhousePrice in a list
                              farmhousePrice: farmhousePrice,
                              selectedServices: selectedServices,
                              pricePerSeat: pricePerSeat, // Pass pricePerSeat
                            ),
                          ),
                        );
                      },
                      child: const Text('Proceed to Booking'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
