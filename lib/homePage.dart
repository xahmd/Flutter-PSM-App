import 'package:flutter/material.dart';
import 'pages/payment/payment_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _onSectionTap(BuildContext context, String sectionName) {
    if (sectionName == "Payment") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PaymentPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$sectionName page clicked (to be implemented)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: SingleChildScrollView( //  Make the page scrollable
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
                shrinkWrap: true, //  Ensure GridView takes only needed height
                physics: const NeverScrollableScrollPhysics(), //  Prevent internal scrolling
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
