import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Intl প্যাকেজ ইম্পোর্ট করতে হবে

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Firebase থেকে নোটিফিকেশন ফেচ করার Stream
  Stream<QuerySnapshot> getNotifications() {
    return FirebaseFirestore.instance
        .collection('our notifications')
        .orderBy('time', descending: true)
        .snapshots();
  }

  // Timestamp থেকে সঠিক ফরম্যাটে সময় কনভার্ট করার ফাংশন
  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime); // AM/PM সহ ফরম্যাট
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getNotifications(),
        builder: (context, snapshot) {
          // যদি ডেটা লোড না হয়
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // যদি কোন নোটিফিকেশন না থাকে
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No notifications available',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            );
          }

          // যদি ডেটা থাকে, লিস্ট আকারে দেখানো
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              String title = doc['title'];
              String description = doc['description'];
              String? imageUrl = doc['image'];
              Timestamp timestamp = doc['time']; // Timestamp হিসেবে ডেটা নিয়ে আসা
              String formattedTime = formatTimestamp(timestamp); // ফরম্যাট করা সময়
              bool isExpanded = false;

              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Card(
                    color: Colors.lightBlue.shade50,
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    child: Column(
                      children: [
                        ListTile(
                          leading: GestureDetector(
                            onTap: () {
                              if (imageUrl != null && imageUrl.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.network(imageUrl),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text('Close'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(
                              imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                                : Icon(Icons.notifications, color: Colors.teal, size: 40),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formattedTime, style: TextStyle(color: Colors.grey)),
                              SizedBox(height: 5),
                              isExpanded
                                  ? Text(description)
                                  : Text(
                                '${description.split(' ').take(15).join(' ')}...',
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    isExpanded = !isExpanded;
                                  });
                                },
                                child: Text(isExpanded ? 'Click to see less' : 'Click to see more'),
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.teal),
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
//cholbe click to see more button ase
