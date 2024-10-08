import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime _selectedDate = DateTime.now();
  String _selectedPeriod = 'Daily';
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  String _selectedYear = DateFormat('yyyy').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Business Dashboard'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & Period Filter
            _buildDateFilter(),
            SizedBox(height: 20),

            // First two cards in a row
            Row(
              children: [
                // Total Purchases
                Expanded(
                  child: _buildColorfulCard(
                    title: 'Total Purchases',
                    value: '\$10,000',
                    subValue1: 'Paid Instantly: \$7,000',
                    subValue2: 'Pending: \$3,000',
                    icon: Icons.shopping_bag_outlined,
                    gradientColors: [Colors.blue, Colors.blueAccent],
                  ),
                ),
                SizedBox(width: 20), // Add some space between the two cards

                // Total Sales
                Expanded(
                  child: _buildColorfulCard(
                    title: 'Total Sales',
                    value: '\$15,000',
                    subValue1: 'Hand-to-hand: \$10,000',
                    subValue2: 'Receivable: \$5,000',
                    icon: Icons.attach_money_outlined,
                    gradientColors: [Colors.green, Colors.lightGreen],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),


            // // Purchases Section
            // _buildColorfulCard(
            //   title: 'Total Purchases',
            //   value: '\$10,000',
            //   subValue1: 'Paid Instantly: \$7,000',
            //   subValue2: 'Pending: \$3,000',
            //   icon: Icons.shopping_bag_outlined,
            //   gradientColors: [Colors.blue, Colors.blueAccent],
            // ),
            // SizedBox(height: 20),
            //
            // // Sales Section
            // _buildColorfulCard(
            //   title: 'Total Sales',
            //   value: '\$15,000',
            //   subValue1: 'Hand-to-hand: \$10,000',
            //   subValue2: 'Receivable: \$5,000',
            //   icon: Icons.attach_money_outlined,
            //   gradientColors: [Colors.green, Colors.lightGreen],
            // ),
            // SizedBox(height: 20),

            // Expenses Section
            _buildColorfulCard(
              title: 'Total Expenses',
              value: '\$5,000',
              icon: Icons.money_off_outlined,
              gradientColors: [Colors.redAccent, Colors.red],
            ),
            SizedBox(height: 20),

            // Cashbox Section (only for daily view)
            if (_selectedPeriod == 'Daily' || _selectedPeriod == 'Weekly' || _selectedPeriod == 'Monthly'||_selectedPeriod == 'Yearly')
              _buildColorfulCard(
                title: 'Cashbox',
                value: '\$2,000',
                icon: Icons.savings_outlined,
                gradientColors: [Colors.purple, Colors.deepPurple],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearPicker() {
    return DropdownButton<String>(
      value: _selectedYear,
      onChanged: (String? newValue) {
        setState(() {
          _selectedYear = newValue!;
        });
      },
      items: List.generate(10, (index) {
        String year = (DateTime.now().year - index).toString();
        return DropdownMenuItem<String>(
          value: year,
          child: Text(year),
        );
      }).toList(),
    );
  }


  // Date Filter with Period Selection (Monthly, Yearly, etc.)
  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Period:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            DropdownButton<String>(
              value: _selectedPeriod,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPeriod = newValue!;
                });
              },
              items: ['Daily', 'Weekly', 'Monthly', 'Yearly']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(width: 20),
            if (_selectedPeriod == 'Monthly' ) _buildMonthYearPicker(),
            if (_selectedPeriod == 'Yearly') _buildYearPicker(),
          ],
        ),
      ],
    );
  }

  // Combined Month and Year Picker
  Widget _buildMonthYearPicker() {
    return Row(
      children: [
        DropdownButton<String>(
          value: _selectedMonth,
          onChanged: (String? newValue) {
            setState(() {
              _selectedMonth = newValue!;
            });
          },
          items: List.generate(12, (index) {
            String month = DateFormat('MMMM').format(DateTime(2020, index + 1, 1));
            return DropdownMenuItem<String>(
              value: month,
              child: Text(month),
            );
          }).toList(),
        ),
        SizedBox(width: 10),
        DropdownButton<String>(
          value: _selectedYear,
          onChanged: (String? newValue) {
            setState(() {
              _selectedYear = newValue!;
            });
          },
          items: List.generate(10, (index) {
            String year = (DateTime.now().year - index).toString();
            return DropdownMenuItem<String>(
              value: year,
              child: Text(year),
            );
          }).toList(),
        ),
      ],
    );
  }

  // A Colorful Card with Gradient Background
  Widget _buildColorfulCard({
    required String title,
    required String value,
    String? subValue1,
    String? subValue2,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 28, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (subValue1 != null)
                Text(
                  subValue1,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              if (subValue2 != null)
                Text(
                  subValue2,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
            ],
          ),
        ),
      ),
    );
  }
}