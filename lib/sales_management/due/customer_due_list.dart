import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'add_customer_page.dart';
import 'due_collection.dart';

class DuePage extends StatefulWidget {
  @override
  _DuePageState createState() => _DuePageState();
}

class _DuePageState extends State<DuePage> {
  String _searchText = ""; // সার্চ টেক্সট ধারণ করার জন্য

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("বাকির খাতা"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddCustomerPage()),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white70,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DueCollectionPage()),
              );
            },
            child: Text('বাকি আদায়'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(height: 10),
            _buildSearchBar(),
            Expanded(child: _buildCustomerList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'কাস্টমার খুঁজুন',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchText = value; // সার্চ টেক্সট আপডেট করুন
        });
      },
    );
  }

  Widget _buildCustomerList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('customers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var customers = snapshot.data?.docs ?? [];

        // সার্চ টেক্সটের উপর ভিত্তি করে গ্রাহকদের তালিকা ফিল্টার করুন
        if (_searchText.isNotEmpty) {
          customers = customers.where((customer) {
            var customerData = customer.data() as Map<String, dynamic>;
            var name = customerData['name'].toString().toLowerCase();
            return name.contains(_searchText.toLowerCase());
          }).toList();
        }

        return ListView.builder(
          itemCount: customers.length,
          itemBuilder: (context, index) {
            var customer = customers[index];
            return _buildCustomerTile(context, customer);
          },
        );
      },
    );
  }

  Widget _buildCustomerTile(BuildContext context, DocumentSnapshot customer) {
    Map<String, dynamic>? customerData = customer.data() as Map<String, dynamic>?;

    String imageUrl = (customerData != null && customerData.containsKey('image'))
        ? customerData['image']
        : 'assets/error.jpg';
    String name = customerData?['name'] ?? 'Unknown';
    String phone = customerData?['phone'] ?? 'Unknown';

    String transaction = (customerData?['transaction'] is List)
        ? (customerData?['transaction'] as List<dynamic>).join(", ")
        : customerData?['transaction']?.toString() ?? '0';

    return ListTile(
      leading: GestureDetector(
        onTap: () {
          _showImageDialog(context, imageUrl, customer);
        },
        child: CircleAvatar(
          backgroundImage: NetworkImage(imageUrl),
          onBackgroundImageError: (_, __) => AssetImage('assets/error.jpg'),
        ),
      ),
      title: Text(name),
      subtitle: Text(phone),
      trailing: Text('৳ $transaction'),
      onTap: () {
        _showEditPopup(context, customer); // এখানে ক্লিক করার ইভেন্ট যুক্ত করুন
      },
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl, DocumentSnapshot customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                imageUrl,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset('assets/error.jpg');
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async {
                      await _pickAndUploadImage(context, customer);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context, DocumentSnapshot customer) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      String fileName = 'customer_images/${customer.id}.jpg';
      try {
        Reference storageReference = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = storageReference.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('customers')
            .doc(customer.id)
            .update({'image': downloadUrl});

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ছবি সফলভাবে আপলোড করা হয়েছে')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ছবি আপলোডে সমস্যা হয়েছে: $e')));
      }
    }
  }

  void _showEditPopup(BuildContext context, DocumentSnapshot customer) {
    TextEditingController nameController = TextEditingController(text: customer['name']);
    TextEditingController phoneController = TextEditingController(text: customer['phone']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // উভয় পাশে স্পেস দেওয়ার জন্য
            children: [
              Text('এডিট করুন'),
              IconButton(
                icon: Icon(Icons.delete_forever_outlined, color: Colors.red), // ডিলিট আইকন
                onPressed: () {
                  _showDeleteConfirmation(context, customer);
                },
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'নাম'),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'ফোন নম্বর'),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // আপডেট করুন বাটন
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('customers')
                        .doc(customer.id)
                        .update({
                      'name': nameController.text,
                      'phone': phoneController.text,
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('সফলভাবে পরিবর্তন হয়েছে')),
                    );
                  },
                  child: Text('পরিবর্তন করুন'),
                ),
                // বাতিল বাটন
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('বাতিল'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, DocumentSnapshot customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ডিলিট নিশ্চিত করুন'),
          content: Text('আপনি কি ${customer['name']} নামের কাস্টমারকে ডিলিট করতে চান? আপনি যদি ডিলিট করেন তাহলে ${customer['name']}-এর বাকির হিসাব আপনার বাকির খাতা থেকে মুছে যাবে।'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('customers')
                    .doc(customer.id)
                    .delete();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('সফল ভাবে ডিলিট হয়েছে')),
                );
              },
              child: Text('হ্যাঁ চাই'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('না'),
            ),
          ],
        );
      },
    );
  }
}
