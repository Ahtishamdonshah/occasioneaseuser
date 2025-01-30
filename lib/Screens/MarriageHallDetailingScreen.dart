import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:occasioneaseuser/Screens/quantitymarriagehall.dart';

class MarriageHallDetailingScreen extends StatefulWidget {
  final String hallId;
  final Map<String, dynamic> hallData;
  final List<Map<String, dynamic>> timeSlots;

  const MarriageHallDetailingScreen({
    Key? key,
    required this.hallId,
    required this.hallData,
    required this.timeSlots,
  }) : super(key: key);

  @override
  _MarriageHallDetailingScreenState createState() =>
      _MarriageHallDetailingScreenState();
}

class _MarriageHallDetailingScreenState
    extends State<MarriageHallDetailingScreen> {
  List<Map<String, dynamic>> selectedServices = [];
  final TextEditingController _personsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    int minCapacity = widget.hallData['minCapacity'] ?? 0;
    int maxCapacity = widget.hallData['maxCapacity'] ?? 0;
    double pricePerSeat = widget.hallData['pricePerSeat'] ?? 0.0;
    List<Map<String, dynamic>> additionalServices =
        List<Map<String, dynamic>>.from(
            widget.hallData['additionalServices'] ?? []);
    final List<String> images =
        List<String>.from(widget.hallData['imageUrls'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hallData['name'],
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (images.isNotEmpty)
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(images[index], fit: BoxFit.cover),
                      );
                    },
                  ),
                ),
              SizedBox(height: 20),

              // Hall Details with Professional UI
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location:',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900)),
                    Text(widget.hallData['location'],
                        style: TextStyle(fontSize: 16, color: Colors.black87)),
                    SizedBox(height: 10),
                    Text('Capacity:',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900)),
                    Text('$minCapacity - $maxCapacity persons',
                        style: TextStyle(fontSize: 16, color: Colors.black87)),
                    SizedBox(height: 10),
                    Text('Price per Seat:',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900)),
                    Text('\$${pricePerSeat.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Additional Services Display
              if (additionalServices.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Additional Services:',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900)),
                    SizedBox(height: 10),
                    ...additionalServices.map((service) => Card(
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(service['name'],
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('\$${service['price']} per unit'),
                            trailing: Checkbox(
                              value: selectedServices.contains(service),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    selectedServices.add(service);
                                  } else {
                                    selectedServices.remove(service);
                                  }
                                });
                              },
                            ),
                          ),
                        )),
                  ],
                ),
              SizedBox(height: 20),

              TextFormField(
                controller: _personsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Number of Persons',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of persons';
                  }
                  final numPersons = int.tryParse(value);
                  if (numPersons == null) {
                    return 'Please enter a valid number';
                  }
                  if (numPersons < minCapacity || numPersons > maxCapacity) {
                    return 'Must be between $minCapacity-$maxCapacity';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuantityAndDateMarriageHallScreen(
                          selectedServices: selectedServices,
                          marriageHallId: widget.hallId,
                          timeSlots: widget.timeSlots,
                          pricePerSeat: pricePerSeat,
                          numberOfPersons:
                              int.parse(_personsController.text.trim()),
                          hallData: widget.hallData,
                        ),
                      ),
                    );
                  }
                },
                child:
                    Text('Proceed to Booking', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
