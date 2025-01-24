import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:occasioneaseuser/Screens/beauty_porlor.dart';
import 'package:occasioneaseuser/Screens/catering.dart';
import 'package:occasioneaseuser/Screens/customscreen.dart';
import 'package:occasioneaseuser/Screens/farmhouse.dart';
import 'package:occasioneaseuser/Screens/marriage_hall.dart';
import 'package:occasioneaseuser/Screens/photographer.dart';
import 'package:occasioneaseuser/Screens/saloon.dart';
import 'package:occasioneaseuser/Screens/search.dart';
import 'package:occasioneaseuser/Screens/weather.dart';
// Import the search screen

class home_screem extends StatefulWidget {
  const home_screem({Key? key}) : super(key: key);

  @override
  _home_screemState createState() => _home_screemState();
}

class _home_screemState extends State<home_screem> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String selectedService = "Asian";
  String? userName;
  List<Map<String, String>> categories = [
    {'name': 'Beauty Parlor', 'imageUrl': 'assets/images/beautyparlour.jpg'},
    {'name': 'Catering', 'imageUrl': 'assets/images/catering.jpg'},
    {'name': 'FarmHouse', 'imageUrl': 'assets/images/farmhoouse.png'},
    {'name': 'Photographer', 'imageUrl': 'assets/images/photographer.jpg'},
    {'name': 'Weather', 'imageUrl': 'assets/images/weather.jpg'},
    {'name': 'Marriage Hall', 'imageUrl': 'assets/images/banquet.jpg'},
    {'name': 'Saloon', 'imageUrl': 'assets/images/saloon.png'},
    {'name': 'Custom', 'imageUrl': 'assets/images/custom.png'}, // New category
  ];

  List<dynamic> topDeals = [];
  List<String> sliderImages = [];
  bool isLoadingDeals = false;
  List<Map<String, dynamic>> searchResults = [];

  @override
  void initState() {
    super.initState();
    _fetchTopDeals();
    _fetchUserName();
    _fetchSliderImages();
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

  Future<void> _fetchUserName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        userName = userDoc['name'];
      });
    }
  }

  Future<void> _fetchSliderImages() async {
    try {
      QuerySnapshot bannerSnapshot =
          await _firestore.collection('promotion_banner').get();
      List<String> imageUrls = [];

      for (var bannerDoc in bannerSnapshot.docs) {
        String serviceName = bannerDoc['serviceName'];
        String docId = bannerDoc['docId'];

        DocumentSnapshot serviceDoc =
            await _firestore.collection(serviceName).doc(docId).get();

        if (serviceDoc.exists) {
          List<dynamic> images = serviceDoc['imageUrls'];
          if (images.isNotEmpty) {
            imageUrls.add(images[0]);
          }
        }
      }

      setState(() {
        sliderImages = imageUrls;
      });
    } catch (e) {
      _showErrorSnackbar(
          "Failed to fetch slider images. Please try again later.");
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
          screen = const MarriageHall();
          break;
        case 'FarmHouse':
          screen = const farmhouse();
          break;
        case 'Photographer':
          screen = const photographer();
          break;
        case 'Saloon':
          screen = const Saloon();
          break;
        case 'Custom': // Handle navigation to CustomScreen
          screen = const ComboDealsSelector();
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

  void _showProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('View Bookings'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to bookings screen
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLikedServicesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Liked Services',
                  style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
              // Add your liked services list here
            ],
          ),
        );
      },
    );
  }

  void _showBookingHistoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Booking History',
                  style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
              // Add your booking history list here
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            snap: true,
            backgroundColor: Colors.blue,
            title: const Text("Home"),
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                _showBookingHistoryModal(context);
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  _showProfileModal(context);
                },
              ),
            ],
            bottom: AppBar(
              backgroundColor: Colors.blue,
              title: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SearchScreen()), // Navigate to the search screen
                  );
                },
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search vendors",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  enabled:
                      false, // Disable the TextField to make it non-editable
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: 20),
                _buildSearchResults(),
                const SizedBox(height: 20),
                _buildCarouselSlider(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Services: ",
                        style: TextStyle(
                            fontSize: 18.0, fontWeight: FontWeight.bold)),
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
                    : _buildTopDealsList(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: "Favorites"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        onTap: (index) {
          if (index == 1) {
            _showLikedServicesModal(context);
          } else if (index == 2) {
            _showProfileModal(context);
          }
        },
      ),
    );
  }

  Widget _buildCarouselSlider() {
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
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(imageUrl,
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width),
              ),
            );
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
        foregroundColor:
            selectedService == service ? Colors.white : Colors.blue,
        backgroundColor:
            selectedService == service ? Colors.blue : Colors.grey[300],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
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

  Widget _buildTopDealsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topDeals.length,
      itemBuilder: (context, index) {
        final deal = topDeals[index];
        return Card(
          child: ListTile(
            leading: deal['imageUrl'] != null
                ? Image.network(deal['imageUrl'], width: 50, height: 50)
                : const Icon(Icons.local_offer),
            title: Text(deal['vendorName'] ?? 'No vendor name'),
            subtitle: Text(deal['description'] ?? 'No description'),
            trailing: ElevatedButton(
              onPressed: () {
                // Handle view button press
                print('View button pressed for ${deal['vendorName']}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('View'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final vendor = searchResults[index];
        return Card(
          child: ListTile(
            leading: vendor['imageUrl'] != null
                ? Image.network(vendor['imageUrl'], width: 50, height: 50)
                : const Icon(Icons.store),
            title: Text(vendor['name'] ?? 'No name'),
            subtitle: Text(vendor['location'] ?? 'No location'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  searchResults.removeAt(index);
                });
              },
            ),
          ),
        );
      },
    );
  }
}
