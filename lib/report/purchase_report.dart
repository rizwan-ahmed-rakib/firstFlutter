import 'package:flutter/material.dart';

// Transaction model
class Transaction {
  final String id;
  final double amount;
  final double payment;
  final String details;

  Transaction(
      {required this.id,
        required this.amount,
        required this.payment,
        required this.details});
}

class SupplyerLendingReport extends StatefulWidget {
  @override
  _SupplyerLendingReportState createState() => _SupplyerLendingReportState();
}

class _SupplyerLendingReportState extends State<SupplyerLendingReport> {
  // Sample transactions
  List<Transaction> transactions = [
    Transaction(
        id: '1',
        amount: 200.00,
        payment: 100.00,
        details: 'Purchase of product X'),
    Transaction(
        id: '2',
        amount: 300.00,
        payment: 50.00,
        details: 'Purchase of product Y'),
    Transaction(
        id: '3',
        amount: 500.00,
        payment: 100.00,
        details: 'Purchase of product Z'),
  ];

  double get totalDebt =>
      transactions.fold(0, (sum, transaction) => sum + transaction.amount);

  double get totalCashGiven =>
      transactions.fold(0, (sum, transaction) => sum + transaction.payment);

  double get cumulativeRemaining {
    double remaining = totalDebt; // Start with total debt
    for (var transaction in transactions) {
      remaining -= transaction.payment; // Deduct payment from remaining
    }
    return remaining;
  }

  // Calculate sub_total_remaining
  double getSubTotalRemaining(int index) {
    double subTotal = 0;
    for (int i = 0; i <= index; i++) {
      subTotal += transactions[i].amount - transactions[i].payment;
    }
    return subTotal > cumulativeRemaining ? cumulativeRemaining : subTotal;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Lending Report'),
        backgroundColor: Color(0xFF1E88E5), // Deep Blue primary color
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              // Add download functionality here
              print("Downloading report...");
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Customer Information
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF80DEEA), Color(0xFF1E88E5)],
                    // Gradient: Cyan to Deep Blue
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Name: John Doe',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // White text for contrast
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Total Debt: ৳${totalDebt.toStringAsFixed(2)}',
                      style:
                      TextStyle(color: Colors.white70), // Subtle white text
                    ),
                    Text(
                      'Cash Given: ৳${totalCashGiven.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Remaining: ৳${cumulativeRemaining.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Transaction History
              Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242), // Dark Gray text for clarity
                ),
              ),
              SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  // Reverse index to show the latest transaction first
                  Transaction transaction =
                  transactions[transactions.length - 1 - index];

                  return Card(
                    color: Color(0xFFEDE7F6),
                    // Light Purple background for cards
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      // Reduced padding for smaller card size
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // First Column (Transaction ID, Date-time, Details, Amount)
                              Flexible(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Transaction #${transaction.id}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: screenWidth * 0.04,
                                        color: Color(
                                            0xFFAB47BC), // Purple text for transaction ID
                                      ),
                                    ),
                                    Text(
                                      'Date: ${DateTime.now()}',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    // Space between the lines
                                    Text(
                                      'Amount: ৳${transaction.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Details: ${transaction.details}',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Second Column (Payment and Remaining)
                              Flexible(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Payment: ৳${transaction.payment.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        color: Color(
                                            0xFF388E3C), // Green text for payment
                                      ),
                                    ),
                                    Text(
                                      'Remaining: ৳${(transaction.amount - transaction.payment).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        color: Color(
                                            0xFFD32F2F), // Red for remaining
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Third Column (Sub Total Remaining)
                              Flexible(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sub Total Remaining',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: screenWidth * 0.035,
                                        color: Color(
                                            0xFFAB47BC), // Purple for consistency
                                      ),
                                    ),
                                    Text(
                                      '৳${getSubTotalRemaining(transactions.length - 1 - index).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      // Bottom Bar for Total Values
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey[200], // Light background for bottom bar
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 10, // Space between the items in case they overflow
            children: [
              // Total Amount and Total Cash Given
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount: ৳${totalDebt.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width *
                          0.03, // Scaled font size
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Total Cash Given: ৳${totalCashGiven.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width *
                          0.03, // Scaled font size
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C), // Green for payment
                    ),
                  ),
                ],
              ),
              // Total Remaining
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Remaining: ৳${cumulativeRemaining.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width *
                          0.03, // Scaled font size
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD32F2F), // Red for remaining balance
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
