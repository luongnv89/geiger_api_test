import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geiger_api/geiger_api.dart';
import 'geiger_api_connector/geiger_api_connector.dart';
import 'geiger_api_connector/sensor_node_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

const String montimagePluginId = 'geiger-api-test-external-plugin-id';

class _MyHomePageState extends State<MyHomePage> {
  List<Message> events = [];
  String userData = '';
  String deviceData = '';
  bool isInProcessing = false;
  bool isMasterStarted = false;
  bool isExternalPluginStarted = false;
  String? masterOutput;
  String? pluginOutput;

  GeigerApiConnector masterApiConnector =
      GeigerApiConnector(pluginId: GeigerApi.masterId);
  GeigerApiConnector pluginApiConnector =
      GeigerApiConnector(pluginId: montimagePluginId);
  SensorDataModel userNodeDataModel = SensorDataModel(
      sensorId: 'mi-cyberrange-score-sensor-id',
      name: 'MI Cyberrange Score',
      minValue: '0',
      maxValue: '100',
      valueType: 'double',
      flag: '1',
      threatsImpact:
          '80efffaf-98a1-4e0a-8f5e-gr89388352ph,High;80efffaf-98a1-4e0a-8f5e-gr89388354sp,Hight;80efffaf-98a1-4e0a-8f5e-th89388365it,Hight;80efffaf-98a1-4e0a-8f5e-gr89388350ma,Medium;80efffaf-98a1-4e0a-8f5e-gr89388356db,Medium');
  SensorDataModel deviceNodeDataModel = SensorDataModel(
      sensorId: 'mi-ksp-scanner-is-rooted-device',
      name: 'Is device rooted',
      minValue: 'false',
      maxValue: 'true',
      valueType: 'boolean',
      flag: '0',
      threatsImpact:
          '80efffaf-98a1-4e0a-8f5e-gr89388352ph,High;80efffaf-98a1-4e0a-8f5e-gr89388354sp,Hight;80efffaf-98a1-4e0a-8f5e-th89388365it,Hight;80efffaf-98a1-4e0a-8f5e-gr89388350ma,Medium;80efffaf-98a1-4e0a-8f5e-gr89388356db,Medium');

  Future<bool> initMasterPlugin() async {
    final bool initGeigerAPI = await masterApiConnector.connectToGeigerAPI();
    if (initGeigerAPI == false) return false;
    final bool initLocalStorage =
        await masterApiConnector.connectToLocalStorage();
    if (initLocalStorage == false) return false;
    final bool regPluginListener =
        await masterApiConnector.registerPluginListener();
    final bool regStorageListener =
        await masterApiConnector.registerStorageListener();
    isMasterStarted = true;
    return regPluginListener && regStorageListener;
  }

  Future<bool> initExternalPlugin() async {
    final bool initGeigerAPI = await pluginApiConnector.connectToGeigerAPI();
    if (initGeigerAPI == false) return false;
    bool initLocalStorage = await pluginApiConnector.connectToLocalStorage();
    if (initLocalStorage == false) return false;

    // Prepare some data roots
    initLocalStorage = await pluginApiConnector.prepareRoot([
      'Device',
      pluginApiConnector.currentDeviceId!,
      montimagePluginId,
      'data',
      'metrics'
    ], '');
    if (initLocalStorage == false) return false;
    initLocalStorage = await pluginApiConnector.prepareRoot([
      'Users',
      pluginApiConnector.currentUserId!,
      montimagePluginId,
      'data',
      'metrics'
    ], '');
    if (initLocalStorage == false) return false;
    initLocalStorage = await pluginApiConnector.prepareRoot([
      'Chatbot',
      'sensors',
      montimagePluginId,
    ], '');
    if (initLocalStorage == false) return false;

    // Prepare some data nodes
    initLocalStorage =
        await pluginApiConnector.addDeviceSensorNode(deviceNodeDataModel);
    if (initLocalStorage == false) return false;
    initLocalStorage =
        await pluginApiConnector.addUserSensorNode(userNodeDataModel);
    if (initLocalStorage == false) return false;

    // Prepare for plugin event handler
    pluginApiConnector.addPluginEventhandler(MessageType.scanPressed,
        (Message msg) async {
      await pluginApiConnector.sendDeviceSensorData(
        deviceNodeDataModel.sensorId,
        Random().nextBool().toString(),
      );
      await pluginApiConnector.sendUserSensorData(
        userNodeDataModel.sensorId,
        Random().nextInt(100).toString(),
      );
    });
    final bool regPluginListener =
        await pluginApiConnector.registerPluginListener();

    // Prepare for storage event handler
    final bool regStorageListener = await pluginApiConnector
        .registerStorageListener(searchPath: ':Chatbot:sensors');
    isExternalPluginStarted = true;
    return regPluginListener && regStorageListener;
  }

  _showSnackBar(String message) {
    SnackBar snackBar = SnackBar(
      content: Text(message),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const TabBar(
            tabs: [
              Tab(
                icon: Icon(
                  Icons.center_focus_strong_outlined,
                ),
                text: 'Geiger Toolbox (Backend)',
              ),
              Tab(
                icon: Icon(Icons.extension_rounded),
                text: 'External Plugin',
              ),
            ],
          ),
        ),
        body: isInProcessing == true
            ? const Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.orange,
                ),
              )
            : TabBarView(
                children: [
                  _viewBackendView(),
                  _viewExternalPluginView(),
                ],
              ),
      ),
    );
  }

  _viewBackendView() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 5),
            const Text(
              'Geiger Toolbox (Backend)',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.orange),
            ),
            !isMasterStarted
                ? Column(children: [
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          isInProcessing = true;
                        });
                        final bool masterPlugin = await initMasterPlugin();
                        if (masterPlugin == false) {
                          _showSnackBar('Failed to start Master Plugin');
                        } else {
                          _showSnackBar('The Master Plugin has been started');
                        }
                        setState(() {
                          isInProcessing = false;
                        });
                      },
                      child: const Text('Start Master Plugin'),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.orange,
                        minimumSize: const Size.fromHeight(40),
                      ),
                    ),
                    const Text('The Master Plugin is not intialized yet!'),
                  ])
                : Column(
                    children: [
                      const Text(
                        'Backend is running...',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.green),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool sentScanPressed = await masterApiConnector
                              .sendPluginEventType(MessageType.scanPressed);
                          if (sentScanPressed == false) {
                            _showSnackBar('Failed to send SCAN_PRESSED event');
                          } else {
                            _showSnackBar('A SCAN_PRESSED event has been sent');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        child: const Text('Send SCAN_PRESSED'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          final String storageStr =
                              await masterApiConnector.dumpLocalStorage(':');
                          setState(() {
                            masterOutput = storageStr;
                          });
                        },
                        child: const Text('Dump Storage'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final String allEventStr =
                              masterApiConnector.showAllPluginEvents();
                          setState(() {
                            masterOutput = allEventStr;
                          });
                        },
                        child: const Text('Show all plugin events'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final String allStorageStr =
                              masterApiConnector.showAllStorageEvents();
                          setState(() {
                            masterOutput = allStorageStr;
                          });
                        },
                        child: const Text('Show all storage events'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final String? sensorData = await masterApiConnector
                              .readGeigerValueOfDeviceSensor(montimagePluginId,
                                  deviceNodeDataModel.sensorId);
                          setState(() {
                            deviceData = sensorData ?? 'null';
                            masterOutput = 'Device sensors data: $deviceData';
                          });
                        },
                        child: Text(
                            'Show the received device sensor data ($deviceData)'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final String? sensorData = await masterApiConnector
                              .readGeigerValueOfUserSensor(montimagePluginId,
                                  userNodeDataModel.sensorId);
                          setState(() {
                            userData = sensorData ?? 'null';
                            masterOutput = 'User sensors data: $userData';
                          });
                        },
                        child: Text(
                            'Show the received users sensor data ($userData)'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 5),
                      Text(masterOutput != null ? masterOutput! : '<output>'),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  _viewExternalPluginView() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 5),
            const Text(
              'External Plugin',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue),
            ),
            !isExternalPluginStarted
                ? Column(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool externalPlugin =
                              await initExternalPlugin();
                          if (externalPlugin == false) {
                            _showSnackBar('Failed to start External Plugin');
                          } else {
                            _showSnackBar(
                                'The External Plugin has been started');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        child: const Text('Start an External Plugin'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const Text('The external plugin is not initialzed yet!'),
                    ],
                  )
                : Column(
                    children: [
                      const Text(
                        'An external plugin is running...',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.green),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool dataSent =
                              await pluginApiConnector.sendDeviceSensorData(
                                  deviceNodeDataModel.sensorId, "true");
                          if (dataSent == false) {
                            _showSnackBar(
                                'Failed to send a device sensor data');
                          } else {
                            _showSnackBar('A device sensor data has been sent');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        child: const Text('Send a device data'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool dataSent =
                              await pluginApiConnector.sendUserSensorData(
                                  userNodeDataModel.sensorId, "50");
                          if (dataSent == false) {
                            _showSnackBar('Failed to send a user sensor data');
                          } else {
                            _showSnackBar('A user sensor data has been sent');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        child: const Text('Send a user data'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          // trigger/send a SCAN_COMPLETED event
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool sentData = await pluginApiConnector
                              .sendPluginEventType(MessageType.scanCompleted);
                          if (sentData == false) {
                            _showSnackBar(
                                'Failed to send SCAN_COMPLETED event');
                          } else {
                            _showSnackBar(
                                'The SCAN_COMPLETED event has been sent');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        child: const Text('Send SCAN_COMPLETED event'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          // trigger/send a STORAGE_EVENT event
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool sentData = await pluginApiConnector
                              .sendDataNode(
                                  ':Chatbot:sensors:$montimagePluginId:my-sensor-data',
                                  [
                                'category',
                                'isSubmitted',
                                'threatInfo'
                              ],
                                  [
                                'Malware',
                                'false',
                                'This is the threat info'
                              ]);
                          if (sentData == false) {
                            _showSnackBar('Failed to send data to Chatbot');
                          } else {
                            _showSnackBar('Data has been sent to Chatbot');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        child: const Text('Send a threat info to Chatbot'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final String allEventStr =
                              pluginApiConnector.showAllPluginEvents();
                          setState(() {
                            pluginOutput = allEventStr;
                          });
                        },
                        child: const Text('Show all plugin events'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final String allStorageStr =
                              pluginApiConnector.showAllStorageEvents();
                          setState(() {
                            pluginOutput = allStorageStr;
                          });
                        },
                        child: const Text('Show all storage events'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          await pluginApiConnector.close();
                          setState(() {
                            isExternalPluginStarted = false;
                          });
                        },
                        child: const Text('Disconnect'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 5),
                      Text(pluginOutput != null ? pluginOutput! : '<output>'),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
