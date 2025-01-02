import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:occasioneaseuser/Screens/beauty_porlor.dart';
import 'package:occasioneaseuser/Screens/catering.dart';
import 'package:occasioneaseuser/Screens/farmhouse.dart';
import 'package:occasioneaseuser/Screens/marriage_hall.dart';
import 'package:occasioneaseuser/Screens/photographer.dart';
import 'package:occasioneaseuser/Screens/saloon.dart';
import 'package:occasioneaseuser/Screens/weather.dart';

class home_screem extends StatefulWidget {
  const home_screem({Key? key}) : super(key: key);

  @override
  _home_screemState createState() => _home_screemState();
}

class _home_screemState extends State<home_screem> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String selectedService = "Asian";
  List<Map<String, String>> categories = [
    {'name': 'Beauty Parlor', 'imageUrl': 'assets/images/beautyparlour.jpg'},
    {'name': 'Catering', 'imageUrl': 'assets/images/catering.jpg'},
    {'name': 'FarmHouse', 'imageUrl': 'assets/images/farmhoouse.png'},
    {'name': 'Photographer', 'imageUrl': 'assets/images/photographer.jpg'},
    {'name': 'Weather', 'imageUrl': 'assets/images/weather.jpg'},
    {'name': 'Marriage Hall', 'imageUrl': 'assets/images/banquet.jpg'},
    {'name': 'Saloon', 'imageUrl': 'assets/images/saloon.png'},
  ];

  List<dynamic> topDeals = [];
  bool isLoadingDeals = false;

  @override
  void initState() {
    super.initState();
    _fetchTopDeals();
  }

  Future<void> _fetchTopDeals() async {
    setState(() {
      isLoadingDeals = true;
    });
    try {
      QuerySnapshot dealsSnapshot =
          await _firestore.collection('topDeals').get();
      setState(() {
        topDeals = dealsSnapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      _showErrorSnackbar("Failed to fetch top deals. Please try again later.");
    } finally {
      setState(() {
        isLoadingDeals = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _navigateToPage(String categoryName) async {
    try {
      Widget screen;
      switch (categoryName) {
        case 'Weather':
          screen = const Weather();
          break;
        case 'Beauty Parlor':
          screen = const beauty_porlor();
          break;
        case 'Catering':
          screen = const catering();
          break;
        case 'Marriage Hall':
          screen = const marriage_hall();
          break;
        case 'FarmHouse':
          screen = const farmhouse();
          break;
        case 'Photographer':
          screen = const photographer();
          break;
        case 'Saloon':
          screen = const saloon();
          break;
        default:
          throw Exception("Unknown category: $categoryName");
      }
      await Navigator.push(
          context, MaterialPageRoute(builder: (context) => screen));
    } catch (e) {
      _showErrorSnackbar(
          "Failed to navigate to the $categoryName screen. Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'help') {
                print('Help selected');
              } else if (value == 'settings') {
                print('Settings selected');
              } else if (value == 'profile') {
                print('Profile selected');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'help', child: Text('Help')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  print('Search for: $value');
                },
                decoration: const InputDecoration(
                  labelText: "Search categories",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 20),
              _buildCarouselSlider(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildServiceButton("Asian"),
                  const SizedBox(width: 10),
                  _buildServiceButton("European"),
                ],
              ),
              const SizedBox(height: 40),
              const Text("Categories",
                  style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildCategoryList(),
              const SizedBox(height: 40),
              const Text("Top Deals",
                  style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              isLoadingDeals
                  ? const Center(child: CircularProgressIndicator())
                  : topDeals.isEmpty
                      ? _buildPlaceholderList()
                      : _buildTopDealsList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        onTap: (index) {
          if (index == 1) {
            print('Navigate to Profile');
          }
        },
      ),
    );
  }

  Widget _buildCarouselSlider() {
    List<String> sliderImages = [
      'https://via.placeholder.com/400',
      'https://via.placeholder.com/400',
      'https://via.placeholder.com/400',
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 200.0,
        enlargeCenterPage: true,
        autoPlay: true,
        aspectRatio: 16 / 9,
      ),
      items: sliderImages.map((imageUrl) {
        return Builder(
          builder: (BuildContext context) {
            return Image.network(imageUrl,
                fit: BoxFit.cover, width: MediaQuery.of(context).size.width);
          },
        );
      }).toList(),
    );
  }

  Widget _buildServiceButton(String service) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedService = service;
        });
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: selectedService == service
            ? Colors.white
            : const Color.fromARGB(255, 38, 82, 165),
        backgroundColor:
            selectedService == service ? Colors.blue : Colors.grey[300],
      ),
      child: Text(service),
    );
  }

  Widget _buildCategoryList() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () async {
            await _navigateToPage(category['name']!);
          },
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      category['imageUrl']!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category['name']!,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderList() {
    return Center(
      child: Text(
        "No deals available at the moment.",
        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildTopDealsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topDeals.length,
      itemBuilder: (context, index) {
        final deal = topDeals[index] as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.local_offer),
            title: Text(deal['title'] ?? 'Deal'),
            subtitle: Text(deal['description'] ?? 'Description unavailable'),
          ),
        );
      },
    );
  }
}
