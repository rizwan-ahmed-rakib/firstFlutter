import 'package:bebshar_poristhiti/sales_management/due/supplier_payment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'add_supplier_page.dart';

class SupplierPaymentList extends StatefulWidget {
  @override
  _SupplierPaymentListState createState() => _SupplierPaymentListState();
}

class _SupplierPaymentListState extends State<SupplierPaymentList> {
  String _searchText = ""; // সার্চ টেক্সট ধারণ করার জন্য

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("পার্টি/সাপ্লায়ার"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddSupplierPage()),
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
                MaterialPageRoute(builder: (context) => SupplierPaymentPage()),
              );
            },
            child: Text('লেনদেন'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(height: 10),
            _buildSearchBar(),
            Expanded(child: _buildSupplierList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'সাপ্লায়ার খুঁজুন',
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

  Widget _buildSupplierList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('suppliers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var suppliers = snapshot.data?.docs ?? [];

        // সার্চ টেক্সটের উপর ভিত্তি করে গ্রাহকদের তালিকা ফিল্টার করুন
        if (_searchText.isNotEmpty) {
          suppliers = suppliers.where((supplier) {
            var supplierData = supplier.data() as Map<String, dynamic>;
            var name = supplierData['name'].toString().toLowerCase();
            return name.contains(_searchText.toLowerCase());
          }).toList();
        }

        return ListView.builder(
          itemCount: suppliers.length,
          itemBuilder: (context, index) {
            var supplier = suppliers[index];
            return _buildSupplierTile(context, supplier);
          },
        );
      },
    );
  }

  Widget _buildSupplierTile(BuildContext context, DocumentSnapshot supplier) {
    Map<String, dynamic>? supplierData = supplier.data() as Map<String, dynamic>?;

    String imageUrl = (supplierData != null && supplierData.containsKey('image'))
        ? supplierData['image']
        : 'assets/error.jpg';
    String name = supplierData?['name'] ?? 'Unknown';
    String phone = supplierData?['phone'] ?? 'Unknown';

    String transaction = (supplierData?['transaction'] is List)
        ? (supplierData?['transaction'] as List<dynamic>).join(", ")
        : supplierData?['transaction']?.toString() ?? '0';

    return ListTile(
      leading: GestureDetector(
        onTap: () {
          _showImageDialog(context, imageUrl, supplier);
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
        _showEditPopup(context, supplier); // এখানে ক্লিক করার ইভেন্ট যুক্ত করুন
      },
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl, DocumentSnapshot supplier) {
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
                      await _pickAndUploadImage(context, supplier);
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

  Future<void> _pickAndUploadImage(BuildContext context, DocumentSnapshot supplier) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      String fileName = 'supplier_images/${supplier.id}.jpg';
      try {
        Reference storageReference = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = storageReference.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('suppliers')
            .doc(supplier.id)
            .update({'image': downloadUrl});

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ছবি সফলভাবে আপলোড করা হয়েছে')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ছবি আপলোডে সমস্যা হয়েছে: $e')));
      }
    }
  }

  void _showEditPopup(BuildContext context, DocumentSnapshot supplier) {
    TextEditingController nameController = TextEditingController(text: supplier['name']);
    TextEditingController phoneController = TextEditingController(text: supplier['phone']);

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
                  _showDeleteConfirmation(context, supplier);
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
                        .collection('suppliers')
                        .doc(supplier.id)
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

  void _showDeleteConfirmation(BuildContext context, DocumentSnapshot supplier) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ডিলিট নিশ্চিত করুন'),
          content: Text('আপনি কি ${supplier['name']} নামের সাপ্লায়ারকে ডিলিট করতে চান? আপনি যদি ডিলিট করেন তাহলে ${supplier['name']}-এর লেনদেনের হিসাব মুছে যাবে।'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('suppliers')
                    .doc(supplier.id)
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
