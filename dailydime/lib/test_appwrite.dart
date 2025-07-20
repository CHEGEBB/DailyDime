import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'services/appwrite_service.dart';

class TestAppwritePage extends StatefulWidget {
  @override
  _TestAppwritePageState createState() => _TestAppwritePageState();
}

class _TestAppwritePageState extends State<TestAppwritePage> {
  String _status = 'Not tested';

  Future<void> testAppwrite() async {
    try {
      AppwriteService.initialize();
      
      // Test creating a simple document
      final result = await AppwriteService.databases.createDocument(
        databaseId: 'dailydime_db',
        collectionId: 'categories',
        documentId: ID.unique(),
        data: {
          'name': 'Test Category',
          'type': 'expense',
          'is_default': false,
          'usage_count': 0,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      
      setState(() {
        _status = 'Success! Document created: ${result.data['name']}';
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
      appBar: AppBar(title: Text('Test Appwrite')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status),
            ElevatedButton(
              onPressed: testAppwrite,
              child: Text('Test Appwrite Connection'),
            ),
          ],
        ),
      ),
    );
  }
}