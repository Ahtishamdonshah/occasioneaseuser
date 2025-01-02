import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class Weather extends StatefulWidget {
  const Weather({Key? key}) : super(key: key);

  @override
  _WeatherState createState() => _WeatherState();
}

class _WeatherState extends State<Weather> {
  String cityName = "lahore"; // Default city
  String apiKey = '6a3a2e9b089e46a8b31230957243112'; // WeatherAPI key

  // Weather Data
  String temperature = "--";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchWeather(cityName); // Fetch weather data on page load
  }

  // Fetch Weather Data from WeatherAPI
  Future<void> fetchWeather(String city) async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
        'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$city&aqi=no');

    try {
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 10)); // Adding timeout

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          temperature = "${data['current']['temp_c']}°C";
        });
      } else {
        setState(() {
          temperature =
              "Error: Unable to fetch weather data (${response.statusCode}). Please check the city name or API key.";
        });
        debugPrint("Error: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      if (e is http.ClientException) {
        setState(() {
          temperature =
              "Failed to connect to the server. Please check your connection.";
        });
      } else if (e is TimeoutException) {
        setState(() {
          temperature = "Request timed out. Please try again.";
        });
      } else {
        setState(() {
          temperature = "Unknown error occurred. Please try again.";
        });
      }
      debugPrint('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather App"),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        // Temperature Display
                        Text(
                          temperature,
                          style: const TextStyle(
                            fontSize: 40.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Change City Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                                255, 35, 140, 211), // Background color
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          onPressed: () async {
                            final newCity = await _showCityInputDialog(context);
                            if (newCity != null && newCity.isNotEmpty) {
                              setState(() {
                                cityName = newCity;
                                temperature = "Loading...";
                              });
                              fetchWeather(newCity);
                            }
                          },
                          child: const Text(
                            "Change City",
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.bold),
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

  // Dialog to Input City Name
  Future<String?> _showCityInputDialog(BuildContext context) async {
    TextEditingController cityController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter City Name"),
        content: TextField(
          controller: cityController,
          decoration: const InputDecoration(hintText: "City Name"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, cityController.text);
            },
            child: const Text("OK"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, null);
            },
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }
}
