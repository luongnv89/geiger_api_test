import 'dart:async';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:toolbox_api_test/geiger_connector.dart';

GeigerConnector geigerConnector = GeigerConnector();
String? firstData;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await geigerConnector.initGeigerAPI();
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
  List<Message> events = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Geiger Toolbox"),
      ),
      body: Container(
        margin: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text('Built at: ${DateTime.now().toIso8601String()}'),
              Divider(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    events = geigerConnector.getEvents();
                    log('Number of events: ${events.length}');
                  });
                },
                child: const Text('Load Events'),
              ),
              const SizedBox(height: 20),
              Text('Events (${events.length})'),
              SingleChildScrollView(
                child: SizedBox(
                  height: 400,
                  child: ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      List<int> payload = events[index].payload;
                      String payloadText = payload.toString();
                      if (payload.isNotEmpty) {
                        try {
                          payloadText = utf8.decode(payload);
                        } catch (e) {
                          log('Failed to decode payload: ${e.toString()}');
                        }
                      }
                      return ListTile(
                        leading: Text(events[index].type.toString()),
                        title: Text(
                            '${events[index].sourceId}-${events[index].targetId}|$payloadText'),
                      );
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
