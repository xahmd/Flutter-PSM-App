import 'package:flutter/material.dart';
// Update rating system import to use the new dashboard
import 'features/rating/screens/rating_dashboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showRatingSection = false;

  void _onSectionTap(BuildContext context, String sectionName) {
    if (sectionName == "Rating") {
      setState(() {
        _showRatingSection = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$sectionName page clicked (to be implemented)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If rating section is shown, display it instead of regular home content
    if (_showRatingSection) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rating System'),
          backgroundColor: const Color(0xFF2C3E50),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _showRatingSection = false;
              });
            },
          ),
        ),
        body: const RatingDashboard(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome to the Home Page!",
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 30),
              const Text(
                "Go to Section:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.2,
                children: [
                  _buildSectionButton(context, "Payment", Icons.payment),
                  _buildSectionButton(context, "Rating", Icons.star_rate),
                  _buildSectionButton(context, "Schedule", Icons.calendar_today),
                  _buildSectionButton(context, "Inventory", Icons.inventory),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionButton(BuildContext context, String title, IconData icon) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _onSectionTap(context, title),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.deepOrange),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
