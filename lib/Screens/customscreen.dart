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
    'Catering',
    'Photographer',
    'Marriage Hall',
    'Beauty Parlor',
    'Salon',
    'Farmhouse'
  ];
  final List<String> _selectedServices = [];
  Map<String, dynamic> _comboDeal = {};
  bool _isLoading = false;

  Future<void> _fetchComboDeals() async {
    final int? budget = int.tryParse(_budgetController.text);
    if (budget == null || budget <= 0 || _selectedServices.isEmpty) {
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
      // Query Firebase for the selected services
      Map<String, dynamic> fetchedServices = {};
      int remainingBudget = budget;

      for (String service in _selectedServices) {
        final QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection(service)
            .orderBy('price')
            .get();

        if (snapshot.docs.isNotEmpty) {
          for (var doc in snapshot.docs) {
            final price = doc['price'];
            if (price <= remainingBudget) {
              fetchedServices[service] = {
                'name': doc['name'],
                'price': price,
                'details': doc['details'],
              };
              remainingBudget -= (price as int);
              break;
            }
          }
        }
      }

      // If not all services fit within the budget, notify the user
      if (fetchedServices.length < _selectedServices.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Some services could not be added due to budget constraints')),
        );
      }

      setState(() {
        _comboDeal = fetchedServices;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch combo deals')),
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
            // Enter Budget
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
                hintText: 'Enter budget (e.g., 10000)',
              ),
            ),
            const SizedBox(height: 16),

            // Select Services
            const Text(
              'Select Services:',
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

            // Fetch Combo Deals Button
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

            // Display Combo Deals
            if (_comboDeal.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Best Combo Deal:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._comboDeal.entries.map((entry) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('${entry.key}: ${entry.value['name']}'),
                        subtitle: Text(
                          'Price: \$${entry.value['price']}\nDetails: ${entry.value['details']}',
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
