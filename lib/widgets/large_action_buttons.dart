import 'package:flutter/material.dart'; //d
import '../sales_management/due/add_customer_page.dart';
import '../sales_management/due/add_supplier_page.dart';

class LargeActionButtons extends StatelessWidget {
  final BuildContext context;
  final double screenWidth;
  final double screenHeight;

  LargeActionButtons(this.context, this.screenWidth, this.screenHeight);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLargeActionButton(Icons.shopping_bag, 'ক্রয়', context, Colors.brown),
        _buildLargeActionButton(Icons.shopping_cart_sharp, 'বিক্রয়', context, Colors.indigo),
      ],
    );
  }

  Widget _buildLargeActionButton(IconData icon, String label, BuildContext context, Color color) {
    Color backgroundColor = (label == 'ক্রয়') ? Colors.brown[100]! : Colors.indigo[100]!;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (label == 'ক্রয়') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AddSupplierPage()));
          } else if (label == 'বিক্রয়') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AddCustomerPage()));
          }
        },
        child: Card(
          color: backgroundColor,
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
            child: Column(
              children: [
                Icon(icon, size: 70, color: color),
                SizedBox(height: 10),
                Text(label, style: TextStyle(fontSize: 20, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
