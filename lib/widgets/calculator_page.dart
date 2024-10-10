import 'package:flutter/material.dart';

class CalculatorPage extends StatefulWidget {
  final Function(double) onValueSelected;

  CalculatorPage({required this.onValueSelected});

  @override
  _CalculatorPageState createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String display = ''; // String used to display the current input
  double currentTotal = 0.0; // Holds the cumulative result
  String operation = ''; // Stores the last operation used
  bool shouldCalculate = false; // Determines whether the calculation should happen after an operation

  void onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'C') {
        display = '';
        currentTotal = 0.0;
        operation = '';
        shouldCalculate = false;
      } else if (buttonText == 'DEL') {
        display = display.isNotEmpty ? display.substring(0, display.length - 1) : '';
      } else if (buttonText == '=') {
        _calculateResult(); // Calculate when '=' is pressed
        widget.onValueSelected(currentTotal);
        display = currentTotal.toStringAsFixed(2); // Display the final result
        Navigator.pop(context); // Close the calculator after displaying the result
      } else if (['+', '-', '*', '/'].contains(buttonText)) {
        if (display.isNotEmpty) {
          if (shouldCalculate) {
            _calculateResult(); // Calculate the result for continuous operations
          } else {
            currentTotal = double.tryParse(display) ?? 0.0;
          }
          operation = buttonText; // Store the selected operation
          display = ''; // Clear display for the next input
          shouldCalculate = true; // Set the flag to calculate on next operation
        }
      } else {
        // Append numbers or '.' to the display
        if (buttonText == '.' && display.contains('.')) return; // Prevent multiple decimals
        display += buttonText;
      }
    });
  }

  void _calculateResult() {
    double secondNumber = double.tryParse(display) ?? 0.0;

    switch (operation) {
      case '+':
        currentTotal += secondNumber;
        break;
      case '-':
        currentTotal -= secondNumber;
        break;
      case '*':
        currentTotal *= secondNumber;
        break;
      case '/':
        if (secondNumber != 0) {
          currentTotal /= secondNumber;
        }
        break;
      default:
        break;
    }

    // Reset the operation after calculation
    operation = '';
    shouldCalculate = false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return LayoutBuilder(
      builder: (context, constraints) {
        double buttonSize = constraints.maxWidth * 0.18;

        return AlertDialog(
          backgroundColor: Colors.lightBlue.shade50, // Custom popup background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          title: Column(
            children: [
              Container(
                padding: EdgeInsets.only(bottom: 8.0), // Space between title and underline
                child: Text(
                  'Simple Calculator',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 24, // You can adjust the font size as needed
                  ),
                ),
              ),
              Container(
                height: 2.0, // Height of the underline
                color: Colors.black, // Color of the underline
              ),
            ],
          ),


          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        display.isEmpty ? currentTotal.toStringAsFixed(2) : display,
                        style: TextStyle(
                          fontSize: size.width * 0.08,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.backspace_outlined, color: Colors.redAccent),
                      onPressed: () => onButtonPressed('DEL'),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.02),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.1,
                  children: [
                    ...['7', '8', '9', '/'].map((text) => calcButton(text, buttonSize, Colors.lightBlueAccent)),
                    ...['4', '5', '6', '*'].map((text) => calcButton(text, buttonSize, Colors.lightBlueAccent)),
                    ...['1', '2', '3', '-'].map((text) => calcButton(text, buttonSize, Colors.lightBlueAccent)),
                    calcButton('C', buttonSize, Colors.redAccent),
                    calcButton('0', buttonSize, Colors.lightBlueAccent),
                    calcButton('.', buttonSize, Colors.lightBlueAccent),
                    calcButton('+', buttonSize, Colors.lightBlueAccent),
                  ],
                ),
                SizedBox(height: size.height * 0.02),
                // "=" button spanning the entire row
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => onButtonPressed('='),
                    child: Text(
                      '=',
                      style: TextStyle(
                        fontSize: size.width * 0.07,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: size.height * 0.02), // Centering vertically
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget calcButton(String text, double size, Color color) {
    return ElevatedButton(
      onPressed: () => onButtonPressed(text),
      child: Text(
        text,
        style: TextStyle(
          fontSize: size * 0.35,
          color: Colors.black87,
        ),
      ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(size * 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: color,
      ),
    );
  }
}
