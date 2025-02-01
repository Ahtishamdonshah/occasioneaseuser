import 'package:flutter/material.dart';
import 'package:occasioneaseuser/Screens/heart.dart';
import 'package:occasioneaseuser/Screens/home_screem.dart';

import 'package:occasioneaseuser/Screens/quantitycatering.dart';
import 'package:occasioneaseuser/Screens/viewbooking.dart';

class CateringDetailsScreen extends StatefulWidget {
  final String cateringId;
  final Map<String, dynamic> cateringData;
  final List<Map<String, dynamic>> timeSlots;

  const CateringDetailsScreen({
    Key? key,
    required this.cateringId,
    required this.cateringData,
    required this.timeSlots,
  }) : super(key: key);

  @override
  _CateringDetailsScreenState createState() => _CateringDetailsScreenState();
}

class _CateringDetailsScreenState extends State<CateringDetailsScreen> {
  final Map<String, List<Map<String, dynamic>>> _servicesByCategory = {};
  final Map<String, List<bool>> _selectedSubServices = {};
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    final List<dynamic> services = widget.cateringData['services'] ?? [];
    for (var service in services) {
      final category = service['category'] ?? 'Other';
      if (!_servicesByCategory.containsKey(category)) {
        _servicesByCategory[category] = [];
        _selectedSubServices[category] = [];
      }
      _servicesByCategory[category]!.add(service);
      _selectedSubServices[category]!.add(false);
    }
  }

  void _changeImage(int direction, List<String> images) {
    setState(() {
      _currentImageIndex = (_currentImageIndex + direction) % images.length;
      if (_currentImageIndex < 0) {
        _currentImageIndex = images.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images =
        List<String>.from(widget.cateringData['imageUrls'] ?? []);
    final String name = widget.cateringData['cateringCompanyName'] ?? 'N/A';
    final String location = widget.cateringData['location'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      images[_currentImageIndex],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Text('Image not available')),
                    ),
                    Positioned(
                      left: 10,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => _changeImage(-1, images),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      child: IconButton(
                        icon: Icon(Icons.arrow_forward, color: Colors.white),
                        onPressed: () => _changeImage(1, images),
                      ),
                    ),
                  ],
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
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                  const SizedBox(height: 8),
                  Text('Location: $location',
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 16),
                  const Text('Services:',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                  const SizedBox(height: 8),
                  ..._servicesByCategory.entries.map((entry) {
                    final category = entry.key;
                    final services = entry.value;
                    return ExpansionTile(
                      title: Text(
                        category,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      children: List.generate(services.length, (index) {
                        final service = services[index];
                        final String serviceName = service['name'] ?? 'N/A';
                        final double price = (service['price'] ?? 0).toDouble();
                        return CheckboxListTile(
                          title: Text(serviceName),
                          subtitle:
                              Text('Price: \$${price.toStringAsFixed(2)}'),
                          value: _selectedSubServices[category]![index],
                          onChanged: (bool? value) {
                            setState(() {
                              _selectedSubServices[category]![index] =
                                  value ?? false;
                            });
                          },
                        );
                      }),
                    );
                  }),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        final selectedServices = <Map<String, dynamic>>[];

                        _servicesByCategory.forEach((category, services) {
                          for (int i = 0; i < services.length; i++) {
                            if (_selectedSubServices[category]![i]) {
                              selectedServices.add(services[i]);
                            }
                          }
                        });

                        if (selectedServices.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Please select at least one service'),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuantityCatering(
                              selectedSubservices: selectedServices,
                              cateringId: widget.cateringId,
                              timeSlots: widget.timeSlots,
                            ),
                          ),
                        );
                      },
                      child: const Text('Add Service'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bookings'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => HomeScreen()));
          } else if (index == 1) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => HeartScreen()));
          } else if (index == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => BookingsScreen()));
          }
        },
      ),
    );
  }
}
