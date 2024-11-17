import 'package:flutter/material.dart';

class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text("Shop Owner Profile"),
        backgroundColor: Colors.blue.shade300,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 60,
              // backgroundImage: NetworkImage('https://img.freepik.com/premium-photo/stylish-man-flat-vector-profile-picture-ai-generated_606187-310.jpg'),
              backgroundImage: NetworkImage('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQzCW8ayM9K_iNzX81NSjgpGcl30jDvsTSiIg&s'),
              backgroundColor: Colors.white,
              child: Align(
                alignment: Alignment.bottomRight,
                child: IconButton(
                  icon: Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () {
                    // Add functionality to update profile picture
                  },
                  color: Colors.blue,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Shop Name and Owner Details
            Text(
              "Shop Name",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Owner's Name",
              style: TextStyle(
                fontSize: 18,
                color: Colors.blueGrey,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Phone: +880 123456789",
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey.shade700,
              ),
            ),
            SizedBox(height: 20),

            // Shop Image
            GestureDetector(
              onTap: () {
                // Add functionality to enlarge shop image
              },
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://example.com/shop-image.jpg'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Monthly Payment Status Cards
            Text(
              "Payment Status",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            SizedBox(height: 10),
            PaymentStatusCard(month: "January", status: "Paid", color: Colors.green),
            PaymentStatusCard(month: "February", status: "Pending", color: Colors.red),
            PaymentStatusCard(month: "March", status: "Paid", color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class PaymentStatusCard extends StatelessWidget {
  final String month;
  final String status;
  final Color color;

  PaymentStatusCard({required this.month, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      color: color.withOpacity(0.2),
      child: ListTile(
        leading: Icon(Icons.calendar_today, color: color),
        title: Text(
          month,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        trailing: Text(
          status,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
