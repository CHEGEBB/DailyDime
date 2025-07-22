import 'package:flutter/material.dart';
import 'services/mpesa_service.dart';

class TestMpesaPage extends StatefulWidget {
  @override
  _TestMpesaPageState createState() => _TestMpesaPageState();
}

class _TestMpesaPageState extends State<TestMpesaPage> {
  String _status = 'Not tested';
  final _phoneController = TextEditingController(text: '254700000000');
  final _amountController = TextEditingController(text: '1');

  Future<void> testStkPush() async {
    try {
      final result = await MpesaService.stkPush(
        phoneNumber: _phoneController.text,
        amount: int.parse(_amountController.text),
        accountReference: 'DailyDime',
        transactionDesc: 'Test Payment',
        callbackUrl: 'https://your-callback-url/mpesa-callback',
      );
      
      setState(() {
        _status = 'STK Push sent! CheckoutRequestID: ${result['CheckoutRequestID']}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test M-Pesa')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Amount (KES)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: testStkPush,
              child: Text('Test STK Push'),
            ),
            SizedBox(height: 20),
            Text(_status),
          ],
        ),
      ),
    );
  }
}