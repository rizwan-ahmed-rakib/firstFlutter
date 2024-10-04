import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // For making calls

class Contact {
  String name;
  String phone;
  String type; // Either "সাপ্লায়ার" or "কাস্টোমার"

  Contact({required this.name, required this.phone, required this.type});

  // Convert a Contact into a Map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'type': type,
    };
  }

  // Convert a Map into a Contact.
  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      name: map['name'],
      phone: map['phone'],
      type: map['type'],
    );
  }
}

class ContactManagementPage extends StatefulWidget {
  @override
  _ContactManagementPageState createState() => _ContactManagementPageState();
}

class _ContactManagementPageState extends State<ContactManagementPage> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _contactType = 'কাস্টোমার'; // Default to Customer
  String _searchQuery = '';
  bool _showCustomers = true; // Toggle to show কাস্টোমার by default

  @override
  void initState() {
    super.initState();
    _loadContacts(); // Load contacts from SharedPreferences
  }

  // Load contacts from SharedPreferences
  void _loadContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? contactsJson = prefs.getString('contacts');
    if (contactsJson != null) {
      List<dynamic> contactList = json.decode(contactsJson);
      setState(() {
        _contacts = contactList.map((data) => Contact.fromMap(data)).toList();
        _filteredContacts = _contacts;
      });
    }
  }

  // Save contacts to SharedPreferences
  void _saveContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String contactsJson =
        json.encode(_contacts.map((contact) => contact.toMap()).toList());
    await prefs.setString('contacts', contactsJson);
  }

  // Add a new contact
  void _addContact() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _contacts.add(Contact(
          name: _nameController.text,
          phone: _phoneController.text,
          type: _contactType,
        ));
        _saveContacts(); // Save the updated contact list
        _filteredContacts = _contacts;
      });

      // Clear form fields after submission
      _nameController.clear();
      _phoneController.clear();
      _contactType = 'কাস্টোমার'; // Reset contact type to default
    }
  }

  // Edit an existing contact
  void _editContact(int index) {
    final contact = _contacts[index];
    _nameController.text = contact.name;
    _phoneController.text = contact.phone;
    _contactType = contact.type;

    // Show a dialog to edit contact
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('এডিট করুন'),
          content: _buildForm(),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  setState(() {
                    _contacts[index] = Contact(
                      name: _nameController.text,
                      phone: _phoneController.text,
                      type: _contactType,
                    );
                    _saveContacts(); // Save the updated contact list
                    _filteredContacts = _contacts;
                  });
                  Navigator.of(context).pop(); // Close dialog
                  _nameController.clear();
                  _phoneController.clear();
                }
              },
              child: Text('সংরক্ষণ করুন'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('বাতিল করুন'),
            ),
          ],
        );
      },
    );
  }

  // Remove a contact
  void _removeContact(int index) {
    setState(() {
      _contacts.removeAt(index);
      _saveContacts(); // Save the updated contact list
      _filteredContacts = _contacts;
    });
  }

  // Search function to filter contacts
  void _searchContacts(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredContacts = _contacts
          .where((contact) =>
              contact.name.toLowerCase().contains(_searchQuery) ||
              contact.phone.contains(_searchQuery))
          .toList();
    });
  }

  // Call a contact using the phone dialer
  void _callContact(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneUri';
    }
  }

  // Contact form
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'নাম'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'দয়া করে নাম দিন';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(labelText: 'ফোন নম্বর'),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'দয়া করে ফোন নম্বর দিন';
              }
              return null;
            },
          ),
          DropdownButtonFormField<String>(
            value: _contactType,
            onChanged: (value) {
              setState(() {
                _contactType = value!;
              });
            },
            items: ['কাস্টোমার', 'সাপ্লায়ার']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            decoration: InputDecoration(labelText: 'টাইপ নির্বাচন করুন'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Contact> displayedContacts = _filteredContacts
        .where((contact) =>
            contact.type == (_showCustomers ? 'কাস্টোমার' : 'সাপ্লায়ার'))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('সাপ্লায়ার এবং কাস্টোমার কন্টাক্ট লিস্ট'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                labelText: 'নাম বা ফোন নম্বর দিয়ে সার্চ করুন',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => _searchContacts(value),
            ),
            SizedBox(height: 20),

            // Contact form
            _buildForm(),
            SizedBox(height: 20),

            // Add contact button
            ElevatedButton(
              onPressed: _addContact,
              child: Text('যোগ করুন'),
            ),
            SizedBox(height: 20),

            // Toggle buttons for displaying contacts
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showCustomers = true;
                    });
                  },
                  child: Text('কাস্টোমার দেখুন'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showCustomers ? Colors.blue : Colors.grey,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showCustomers = false;
                    });
                  },
                  child: Text('সাপ্লায়ার দেখুন'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        !_showCustomers ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Contact list
            Expanded(
              child: displayedContacts.isEmpty
                  ? Center(child: Text('কোন কন্টাক্ট পাওয়া যায় নি'))
                  : ListView.builder(
                      itemCount: displayedContacts.length,
                      itemBuilder: (context, index) {
                        final contact = displayedContacts[index];
                        return Card(
                          child: ListTile(
                            title: Text('${contact.name}'),
                            subtitle: Text('ফোন: ${contact.phone}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.phone),
                                  onPressed: () => _callContact(contact.phone),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _editContact(index),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _removeContact(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
