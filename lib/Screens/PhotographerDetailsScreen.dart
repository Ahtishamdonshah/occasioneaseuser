import 'package:flutter/material.dart';
import 'package:occasioneaseuser/Screens/quantityphotographer.dart';

class PhotographerDetailsScreen extends StatefulWidget {
  final String photographerId;
  final Map<String, dynamic> photographerData;
  final List<Map<String, dynamic>> timeSlots;

  const PhotographerDetailsScreen({
    Key? key,
    required this.photographerId,
    required this.photographerData,
    required this.timeSlots,
  }) : super(key: key);

  @override
  _PhotographerDetailsScreenState createState() =>
      _PhotographerDetailsScreenState();
}

class _PhotographerDetailsScreenState extends State<PhotographerDetailsScreen> {
  final Map<String, List<Map<String, dynamic>>> _servicesByCategory = {};
  final Map<String, List<bool>> _selectedSubServices = {};

  @override
  void initState() {
    super.initState();
    final List<dynamic> services = widget.photographerData['services'] ?? [];
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

  @override
  Widget build(BuildContext context) {
    final List<String> images =
        List<String>.from(widget.photographerData['imageUrls'] ?? []);
    final String name = widget.photographerData['photographerName'] ?? 'N/A';
    final String location = widget.photographerData['location'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(title: Text(name)),
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
                      .map((url) => Image.network(url, fit: BoxFit.cover))
                      .toList(),
                ),
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
                            builder: (context) => QuantityPhotographer(
                              selectedSubservices: selectedServices,
                              photographerId: widget.photographerId,
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
    );
  }
}
