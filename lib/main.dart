import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:toolbox_api_test/geiger_connector.dart';

GeigerConnector geigerConnector = GeigerConnector();
String? firstData;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await geigerConnector.initGeigerAPI();
  firstData = await geigerConnector.readDataFromGeigerStorage();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    log('Start building the application');
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Get battery level.
  String geigerData = firstData ?? 'Failed';
  TextEditingController inputDataController = TextEditingController();
  // bool _isReady = isReady;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Geiger API Test"),
      ),
      body: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Built at: ${DateTime.now().toIso8601String()}'),
            const SizedBox(height: 20),
            TextField(
              controller: inputDataController,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                log('Enter data: ${inputDataController.text}');
                String inputData = inputDataController.text.trim();
                if (inputData != '') {
                  await geigerConnector.writeToGeigerStorage(inputData);
                  inputDataController.clear();
                  String? newData =
                      await geigerConnector.readDataFromGeigerStorage();
                  setState(() {
                    geigerData = newData ?? 'Failed!';
                  });
                }
              },
              child: const Text('Save'),
            ),
            const SizedBox(height: 20),
            Text('Geiger Data: $geigerData'),
          ],
        ),
      ),
    );
  }
}
