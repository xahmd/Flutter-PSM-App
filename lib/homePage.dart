import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _onSectionTap(BuildContext context, String sectionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$sectionName page clicked (to be implemented)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: SingleChildScrollView( // ✅ Make the page scrollable
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
                shrinkWrap: true, // ✅ Ensure GridView takes only needed height
                physics: const NeverScrollableScrollPhysics(), // ✅ Prevent internal scrolling
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
    return GestureDetector(
      onTap: () => _onSectionTap(context, title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.orange),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
