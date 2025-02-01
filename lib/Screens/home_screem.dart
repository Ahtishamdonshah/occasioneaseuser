import 'dart:io';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:occasioneaseuser/Screens/beauty_porlor.dart';
import 'package:occasioneaseuser/Screens/catering.dart';
import 'package:occasioneaseuser/Screens/customscreen.dart';
import 'package:occasioneaseuser/Screens/farmhouse.dart';
import 'package:occasioneaseuser/Screens/heart.dart';
import 'package:occasioneaseuser/Screens/historybooking.dart';
import 'package:occasioneaseuser/Screens/marriage_hall.dart';
import 'package:occasioneaseuser/Screens/photographer.dart';
import 'package:occasioneaseuser/Screens/saloon.dart';
import 'package:occasioneaseuser/Screens/search.dart';
import 'package:occasioneaseuser/Screens/viewbooking.dart';
import 'package:occasioneaseuser/Screens/weather.dart';
import 'package:occasioneaseuser/Screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  //final ImagePicker _picker = ImagePicker();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? userName;
  String? userEmail;
  String? profileImageUrl;
  File? _profileImage;
  List<dynamic> topDeals = [];
  List<String> sliderImages = [];
  bool isLoadingDeals = false;

  final List<Map<String, String>> categories = [
    {'name': 'Beauty Parlor', 'imageUrl': 'assets/images/beautyparlour.jpg'},
    {'name': 'Catering', 'imageUrl': 'assets/images/catering.jpg'},
    {'name': 'FarmHouse', 'imageUrl': 'assets/images/farmhoouse.png'},
    {'name': 'Photographer', 'imageUrl': 'assets/images/photographer.jpg'},
    {'name': 'Weather', 'imageUrl': 'assets/images/weather.jpg'},
    {'name': 'Marriage Hall', 'imageUrl': 'assets/images/banquet.jpg'},
    {'name': 'Saloon', 'imageUrl': 'assets/images/saloon.png'},
    {'name': 'Custom', 'imageUrl': 'assets/images/custom.png'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchTopDeals();
    _fetchSliderImages();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          userName = userDoc['name'];
          userEmail = userDoc['email'];
          profileImageUrl = userDoc['profileImageUrl'];
        });
      } catch (e) {
        _showErrorSnackbar("Failed to fetch user data");
      }
    }
  }

  Future<void> _updateProfile() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      String? imageUrl = profileImageUrl;
      if (_profileImage != null) {
        Reference storageRef =
            FirebaseStorage.instance.ref().child('profile_images/${user.uid}');
        await storageRef.putFile(_profileImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      await _firestore.collection('users').doc(user.uid).update({
        'name': userName,
        'profileImageUrl': imageUrl,
      });

      setState(() {
        profileImageUrl = imageUrl;
        _profileImage = null;
      });
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackbar("Failed to update profile");
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName:
                Text(userName ?? '', style: const TextStyle(fontSize: 18)),
            accountEmail:
                Text(userEmail ?? '', style: const TextStyle(fontSize: 14)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!)
                  : const AssetImage('assets/default_profile.png')
                      as ImageProvider,
            ),
            decoration: BoxDecoration(color: Colors.blue[700]),
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Edit Profile',
                style: TextStyle(color: Colors.blue)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => _buildEditProfileScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.book_online, color: Colors.blue),
            title: const Text('Bookings', style: TextStyle(color: Colors.blue)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BookingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.blue),
            title: const Text('Booking History',
                style: TextStyle(color: Colors.blue)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BookingHistoryScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.blue),
            title: const Text('Logout', style: TextStyle(color: Colors.blue)),
            onTap: () async {
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileScreen() {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[700],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              //  onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue[100],
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : (profileImageUrl != null
                            ? NetworkImage(profileImageUrl!)
                            : const AssetImage('assets/default_profile.png'))
                        as ImageProvider,
                child: _profileImage == null && profileImageUrl == null
                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.blue)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: userName,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.person, color: Colors.blue),
              ),
              onChanged: (value) => userName = value,
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: userEmail,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.email, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchTopDeals() async {
    setState(() => isLoadingDeals = true);
    try {
      QuerySnapshot dealsSnapshot =
          await _firestore.collection('topDeals').get();
      setState(() =>
          topDeals = dealsSnapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      _showErrorSnackbar("Failed to fetch top deals");
    } finally {
      setState(() => isLoadingDeals = false);
    }
  }

  Future<void> _fetchSliderImages() async {
    try {
      QuerySnapshot bannerSnapshot =
          await _firestore.collection('promotion_banner').get();
      List<String> imageUrls = [];

      for (var bannerDoc in bannerSnapshot.docs) {
        DocumentSnapshot serviceDoc = await _firestore
            .collection(bannerDoc['serviceName'])
            .doc(bannerDoc['docId'])
            .get();

        if (serviceDoc.exists && serviceDoc['imageUrls'].isNotEmpty) {
          imageUrls.add(serviceDoc['imageUrls'][0]);
        }
      }

      setState(() => sliderImages = imageUrls);
    } catch (e) {
      _showErrorSnackbar("Failed to fetch slider images");
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(), // Moved drawer before title
      appBar: AppBar(
        title: const Text(
          'OCCASSIONEASE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue[700],
        automaticallyImplyLeading: true, // Ensures the drawer icon is displayed
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            snap: true,
            backgroundColor: Colors.blue[700],
            expandedHeight: 60,
            flexibleSpace: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search vendors...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.blue, size: 30),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  enabled: false,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              _buildCarouselSlider(),
              const SizedBox(height: 30),
              _buildCategorySection(),
              const SizedBox(height: 30),
              _buildTopDealsSection(),
              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue[700],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: "Favorites"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const HeartScreen()));
          }
        },
      ),
    );
  }

  Widget _buildCarouselSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200,
        autoPlay: true,
        enlargeCenterPage: true,
        autoPlayInterval: const Duration(seconds: 3),
      ),
      items: sliderImages
          .map((imageUrl) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Categories",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) =>
                _buildCategoryItem(categories[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, String> category) {
    return GestureDetector(
      onTap: () => _navigateToCategory(category['name']!),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.asset(
                  category['imageUrl']!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                category['name']!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDealsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Top Deals",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
          const SizedBox(height: 15),
          isLoadingDeals
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.blue))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topDeals.length,
                  itemBuilder: (context, index) =>
                      _buildDealItem(topDeals[index]),
                ),
        ],
      ),
    );
  }

  Widget _buildDealItem(dynamic deal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: deal['imageUrl'] != null
              ? Image.network(deal['imageUrl'],
                  width: 60, height: 60, fit: BoxFit.cover)
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.blue[100],
                  child: const Icon(Icons.local_offer, color: Colors.blue),
                ),
        ),
        title: Text(deal['vendorName'] ?? 'Vendor',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(deal['description'] ?? 'Description'),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('View', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  void _navigateToCategory(String categoryName) {
    switch (categoryName) {
      case 'Beauty Parlor':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const BeautyParlor()));
        break;
      case 'Catering':
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const Catering()));
        break;
      case 'FarmHouse':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Farmhouse()));
        break;
      case 'Photographer':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Photographer()));
        break;
      case 'Weather':
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const Weather()));
        break;
      case 'Marriage Hall':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const MarriageHall()));
        break;

      case 'Saloon':
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const Salon()));
        break;
      case 'Custom':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ComboDealsSelector()));
        break;
    }
  }
}
