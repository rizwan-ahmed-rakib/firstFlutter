import 'package:flutter/material.dart';
import '../sales_management/due/customer_due_list.dart'; //due page
import '../sales_management/due/supplier_payment.dart';
import '../personal_expense.dart';
import '../sales_management/due/supplier_payment_list.dart';
import '../stock_management_page.dart';

class ActionGrid extends StatelessWidget {
  final BuildContext context;
  final double screenWidth;
  final double screenHeight;

  ActionGrid(this.context, this.screenWidth, this.screenHeight);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildGridItem(Icons.transfer_within_a_station, 'পার্টি লেনদেন', SupplierPaymentPage(), Colors.blue), //parti lenden
        _buildGridItem(Icons.shopping_cart_outlined, 'বিক্রয় সমূহ', DuePage(), Colors.green),
        _buildGridItem(Icons.note_alt, 'বাকির খাতা', DuePage(), Colors.cyan),
        _buildGridItem(Icons.inventory, 'প্রোডাক্ট স্টক', StockManagementPage(), Colors.brown),
        _buildGridItem(Icons.note_alt_outlined, 'খরচের হিসাব', PersonalExpensePage(), Colors.teal),
        _buildGridItem(Icons.people, 'সকল পার্টি', SupplierPaymentList(), Colors.red),
      ],
    );
  }

  Widget _buildGridItem(IconData icon, String label, Widget? page, Color color) {
    return InkWell(
      onTap: () {
        if (page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        }
      },
      child: Card(
        color: color, // Use the passed color here
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50),
            SizedBox(height: 10),
            Text(label, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
