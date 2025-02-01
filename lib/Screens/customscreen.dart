import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class ComboDealsSelector extends StatefulWidget {
  const ComboDealsSelector({Key? key}) : super(key: key);

  @override
  _ComboDealsSelectorState createState() => _ComboDealsSelectorState();
}

class _ComboDealsSelectorState extends State<ComboDealsSelector> {
  final TextEditingController _budgetController = TextEditingController();
  final List<String> _services = [
    'Marriage Halls',
    'Photographer',
    'Saloons',
    'Farm Houses',
    'Catering',
    'Beauty Parlors'
  ];
  final List<String> _selectedServices = [];
  List<Map<String, dynamic>> _comboDeal = [];
  bool _isLoading = false;
  final Random _random = Random();

  int _getVendorPrice(String category, QueryDocumentSnapshot vendor) {
    try {
      switch (category) {
        case 'Marriage Halls':
        case 'Farm Houses':
          final pricePerSeat = vendor['pricePerSeat'] as int;
          final minCapacity = vendor['minCapacity'] as int;
          return pricePerSeat * minCapacity;
        case 'Beauty Parlors':
        case 'Saloons':
        case 'Photographer':
          final services = vendor['services'] as List<dynamic>;
          if (services.isEmpty) return 0;
          return services
              .map<int>((s) => (s as Map<String, dynamic>)['price'] as int)
              .reduce((a, b) => a < b ? a : b);
        case 'Catering':
          return 0;
        default:
          return 0;
      }
    } catch (e) {
      print('Error calculating price: $e');
      return 0;
    }
  }

  String _getVendorName(String category, QueryDocumentSnapshot vendor) {
    switch (category) {
      case 'Marriage Halls':
      case 'Farm Houses':
        return vendor['name'] as String;
      case 'Beauty Parlors':
      case 'Saloons':
        return vendor['parlorName'] as String;
      case 'Photographer':
        return vendor['photographerName'] as String;
      case 'Catering':
        return vendor['cateringCompanyName'] as String;
      default:
        return 'Unknown Vendor';
    }
  }

  String _getVendorDetails(String category, QueryDocumentSnapshot vendor) {
    return vendor['description'] as String? ?? 'No details available';
  }

  Future<void> _fetchComboDeals() async {
    final int? totalBudget = int.tryParse(_budgetController.text);
    if (totalBudget == null || totalBudget <= 0 || _selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please enter a valid budget and select at least one service')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _comboDeal = [];
    });

    try {
      List<Map<String, dynamic>> fetchedVendors = [];
      int remainingBudget = totalBudget;

      for (String service in _selectedServices) {
        final QuerySnapshot snapshot =
            await FirebaseFirestore.instance.collection(service).get();

        if (snapshot.docs.isEmpty) continue;

        List<QueryDocumentSnapshot> eligibleVendors = [];
        for (var doc in snapshot.docs) {
          final vendorPrice = _getVendorPrice(service, doc);
          if (vendorPrice > 0 && vendorPrice <= remainingBudget) {
            eligibleVendors.add(doc);
          }
        }

        if (eligibleVendors.isNotEmpty) {
          final selectedVendor =
              eligibleVendors[_random.nextInt(eligibleVendors.length)];
          final vendorPrice = _getVendorPrice(service, selectedVendor);

          fetchedVendors.add({
            'service': service,
            'name': _getVendorName(service, selectedVendor),
            'price': vendorPrice,
            'details': _getVendorDetails(service, selectedVendor),
          });

          remainingBudget -= vendorPrice;
        }
      }

      setState(() {
        _comboDeal = fetchedVendors;
      });

      if (_comboDeal.length < _selectedServices.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Some services could not be added due to budget constraints')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch combo deals: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Combo Deals Selector'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Your Total Budget:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter budget (e.g., 100000)',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Services (choose one or more):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children: _services.map((service) {
                return CheckboxListTile(
                  title: Text(service),
                  value: _selectedServices.contains(service),
                  onChanged: (isSelected) {
                    setState(() {
                      if (isSelected!) {
                        _selectedServices.add(service);
                      } else {
                        _selectedServices.remove(service);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _fetchComboDeals,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text('Show Combo Deals'),
              ),
            ),
            const SizedBox(height: 16),
            if (_comboDeal.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Budgeting Vendors Package:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._comboDeal.map((vendor) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('${vendor['service']}: ${vendor['name']}'),
                        subtitle: Text(
                          'Price: \$${vendor['price']}\nDetails: ${vendor['details']}',
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  Text(
                    'Total Price: \$${_comboDeal.fold(0, (sum, vendor) => sum + vendor['price'] as int)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_comboDeal.length < _selectedServices.length)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'Note: Some services could not be added due to budget constraints.',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
