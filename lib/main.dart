import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:toolbox_api_test/geiger_connector.dart';
// import 'package:toolbox_api_test/utils.dart';

// GeigerConnector geigerConnector = GeigerConnector();
bool isReady = false;
GeigerApi? geigerApi;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await readPackageInfo();
  isReady = await checkPermissions();
  if (isReady) {
    await initGeigerAPI();
  }
  runApp(MyApp());
}

Future<void> initGeigerAPI() async {
  try {
    geigerApi = await getGeigerApi('<unspecified>', 'miCyberrangePlugin');
  } catch (e) {
    log('Failed to get the GeigerAPI');
    log(e.toString());
  }
}

Future<bool> checkPermissions() async {
  final storagePermissionStatus = await Permission.storage.status;
  print('storagePermissionStatus: $storagePermissionStatus');
  final manageExternalStoragePermissionStatus =
      await Permission.manageExternalStorage.status;
  print(
      'manageExternalStoragePermissionStatus: $manageExternalStoragePermissionStatus');
  if (storagePermissionStatus == PermissionStatus.granted &&
      manageExternalStoragePermissionStatus == PermissionStatus.granted) {
    return true;
  }
  return false;
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
  // String geigerData = 'Failed';
  // TextEditingController inputDataController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Geiger APIs - ${DateTime.now().toIso8601String()}"),
      ),
      body: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // TextField(
            //   controller: inputDataController,
            // ),
            // ElevatedButton(
            //   onPressed: () async {
            //     log('Enter data: ${inputDataController.text}');
            //     String inputData = inputDataController.text.trim();
            //     if (inputData != '') {
            //       await geigerConnector.writeToGeigerStorage(inputData);
            //       inputDataController.clear();
            //       String? newData =
            //           await geigerConnector.readDataFromGeigerStorage();
            //       setState(() {
            //         geigerData = newData ?? 'Failed!';
            //       });
            //     }
            //   },
            //   child: const Text('Save to Geiger Storage'),
            // ),
            // SizedBox(height: 20),
            // Text('Geiger Data: $geigerData'),
            isReady == false
                ? ElevatedButton(
                    onPressed: () async {
                      await _requestPermissions(Permission.storage);
                      await _requestPermissions(
                          Permission.manageExternalStorage);
                      initGeigerAPI();
                    },
                    child: Text('Request Permissions'),
                  )
                : Text('All permissions been granted!'),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPermissions(Permission permission) async {
    var status = await permission.status;
    if (status == PermissionStatus.granted) {
      print('OK! Permission granted');
    } else if (status == PermissionStatus.denied) {
      print('Permission denied. Going to ask for permission');
      status = await permission.request();
      if (status == PermissionStatus.granted) {
        print('Awesome! Permission granted');
      } else if (status == PermissionStatus.denied) {
        print('Ooop! Permission denied');
      }
    } else if (status == PermissionStatus.permanentlyDenied) {
      print('Take the user to the settings page.');
      await openAppSettings();
    }
  }
}
