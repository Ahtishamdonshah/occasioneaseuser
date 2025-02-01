import 'package:flutter/material.dart';
import 'package:occasioneaseuser/Screens/heart.dart';
import 'package:occasioneaseuser/Screens/home_screem.dart';
import 'package:occasioneaseuser/Screens/quantitysaloon.dart';

import 'package:occasioneaseuser/Screens/viewbooking.dart'; // Import BookingsScreen

class SalonDetailsScreen extends StatefulWidget {
  final String salonId;
  final Map<String, dynamic> salonData;
  final List<Map<String, dynamic>> timeSlots;

  const SalonDetailsScreen({
    Key? key,
    required this.salonId,
    required this.salonData,
    required this.timeSlots,
  }) : super(key: key);

  @override
  _SalonDetailsScreenState createState() => _SalonDetailsScreenState();
}

class _SalonDetailsScreenState extends State<SalonDetailsScreen> {
  final Map<String, List<Map<String, dynamic>>> _servicesByCategory = {};
  final Map<String, List<bool>> _selectedSubServices = {};
  int _selectedIndex = 0; // To track selected bottom navigation tab
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    final List<dynamic> services = widget.salonData['services'] ?? [];
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

  // Bottom Navigation Bar items
  final List<Widget> _pages = [
    HomeScreen(), // Home Screen widget
    HeartScreen(), // Heart Screen widget
    BookingsScreen(), // Bookings Screen widget
  ];

  // Navigation to the corresponding screen
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Use the Navigator to navigate to the selected page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => _pages[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images =
        List<String>.from(widget.salonData['imageUrls'] ?? []);
    final String name = widget.salonData['parlorName'] ?? 'N/A';
    final String location = widget.salonData['location'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.blue, // Blue color for AppBar
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              Stack(
                children: [
                  Container(
                    height: 200,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          images[index],
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 90,
                    left: 10,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (_pageController.page! > 0) {
                          _pageController.previousPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut);
                        }
                      },
                    ),
                  ),
                  Positioned(
                    top: 90,
                    right: 10,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (_pageController.page! < images.length - 1) {
                          _pageController.nextPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut);
                        }
                      },
                    ),
                  ),
                ],
              )
            else
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No images available'))),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Location: $location', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 16),
                  Text('Services:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ..._servicesByCategory.entries.map((entry) => ExpansionTile(
                        title: Text(entry.key,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        children: List.generate(entry.value.length, (index) {
                          final service = entry.value[index];
                          return CheckboxListTile(
                            title: Text(service['name']),
                            subtitle: Text('Price: \$${service['price']}'),
                            value: _selectedSubServices[entry.key]![index],
                            onChanged: (bool? value) => setState(() =>
                                _selectedSubServices[entry.key]![index] =
                                    value ?? false),
                          );
                        }),
                      )),
                  SizedBox(height: 16),
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
                                    Text('Please select at least one service')),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuantitySaloon(
                              selectedSubservices: selectedServices,
                              salonId: widget.salonId,
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
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor:
            Colors.blue[700], // Blue color for bottom navigation bar
        selectedItemColor: Colors.white, // White color for selected icon
        unselectedItemColor: Colors.white60, // Light color for unselected icons
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Heart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Bookings',
          ),
        ],
      ),
    );
  }
}
