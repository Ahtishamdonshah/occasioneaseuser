import 'package:flutter/material.dart';
import 'package:occasioneaseuser/Screens/quantityanddatefarmhouse.dart';

class FarmhouseDetailingScreen extends StatefulWidget {
  final String farmhouseId;
  final Map<String, dynamic> farmhouseData;
  final List<Map<String, dynamic>> timeSlots;

  const FarmhouseDetailingScreen({
    Key? key,
    required this.farmhouseId,
    required this.farmhouseData,
    required this.timeSlots,
  }) : super(key: key);

  @override
  _FarmhouseDetailingScreenState createState() =>
      _FarmhouseDetailingScreenState();
}

class _FarmhouseDetailingScreenState extends State<FarmhouseDetailingScreen> {
  List<Map<String, dynamic>> selectedServices = [];
  final TextEditingController _personsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(widget.farmhouseData['imageUrls'] ?? []);
    int minCapacity = widget.farmhouseData['minCapacity'] ?? 0;
    int maxCapacity = widget.farmhouseData['maxCapacity'] ?? 0;
    double pricePerSeat = widget.farmhouseData['pricePerSeat'] ?? 0.0;
    List<Map<String, dynamic>> additionalServices =
        List<Map<String, dynamic>>.from(
            widget.farmhouseData['additionalServices'] ?? []);

    return Scaffold(
      appBar: AppBar(title: Text(widget.farmhouseData['name'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) => Image.network(
                    images[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Location: ${widget.farmhouseData['location']}'),
              Text('Capacity: $minCapacity - $maxCapacity persons'),
              Text('Price per Seat: \$${pricePerSeat.toStringAsFixed(2)}'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _personsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of Persons',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final num = int.tryParse(value);
                  if (num == null) return 'Invalid number';
                  if (num < minCapacity || num > maxCapacity) {
                    return 'Must be between $minCapacity-$maxCapacity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Additional Services:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...additionalServices.map((service) => CheckboxListTile(
                    title: Text('${service['name']} - \$${service['price']}'),
                    value: selectedServices.contains(service),
                    onChanged: (value) => setState(() {
                      if (value!) {
                        selectedServices.add(service);
                      } else {
                        selectedServices.remove(service);
                      }
                    }),
                  )),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuantityAndDateFarmhouseScreen(
                          selectedServices: selectedServices,
                          farmhouseId: widget.farmhouseId,
                          timeSlots: widget.timeSlots,
                          pricePerSeat: pricePerSeat,
                          numberOfPersons:
                              int.parse(_personsController.text.trim()),
                          farmhouseData: widget.farmhouseData,
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Proceed to Booking'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 0),
    );
  }

  BottomNavigationBar _buildBottomNavBar(BuildContext context, int index) {
    return BottomNavigationBar(
      currentIndex: index,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (idx) {
        if (idx == 1) Navigator.pushNamed(context, '/favorites');
        if (idx == 2) Navigator.pushNamed(context, '/profile');
      },
    );
  }
}
