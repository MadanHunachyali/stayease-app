import 'package:flutter/material.dart';
import 'pg_search_screen.dart';
import 'pg_login_screen.dart';
import 'pg_registration_screen.dart';
import 'profile_screen.dart'; // <-- Dummy screen will be this for now, you can replace it
import 'agreement_screen.dart';
import 'pgid_screen.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;

  const HomePage({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;

  final List<Widget> _screens = [
    HomeScreen(),
    PGSearchScreen(),
    PgLoginScreen(),
    PgIdScreen(),
    AgreementGenerator(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("STAYEASE", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        ProfileScreen()), // Replace with your desired screen
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search PG"),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: "My PG"),
          BottomNavigationBarItem(icon: Icon(Icons.vpn_key), label: "PG ID"),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment), label: "Agreement"),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.28,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/mainhome.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome to StayEase!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Stayease is your all-in-one PG management and discovery platform. PG owners can easily register and manage their properties, while residents can explore the best PGs nearby, compare based on amenities, reviews, and ratings — all in one app!",
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "We are dedicated to transforming the PG experience for both owners and residents. Our mission is to make accommodation more accessible, transparent, and organized through modern digital tools.",
                          style: TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PGRegistrationScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        "Register PG",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
