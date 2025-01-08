import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    });

    try {
      List<Map<String, dynamic>> fetchedVendors = [];
      int remainingBudget = totalBudget;
      int budgetPerService = totalBudget ~/ _selectedServices.length;

      for (String service in _selectedServices) {
        // Query for vendors with prices close to the allocated budget
        final QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection(service)
            .orderBy('price')
            .startAt([budgetPerService * 0.8]).endAt(
                [budgetPerService * 1.2]).get();

        if (snapshot.docs.isNotEmpty) {
          // Find the vendor with the closest price to budgetPerService
          var closestVendor = snapshot.docs.reduce((a, b) {
            int priceA = a['price'] as int;
            int priceB = b['price'] as int;
            return (priceA - budgetPerService).abs() <
                    (priceB - budgetPerService).abs()
                ? a
                : b;
          });

          final price = closestVendor['price'] as int;
          if (price <= remainingBudget) {
            fetchedVendors.add({
              'service': service,
              'name': closestVendor['name'],
              'price': price,
              'details': closestVendor['details'],
            });
            remainingBudget -= price;
          }
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
                    'Best Combo Deal:',
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
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
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
