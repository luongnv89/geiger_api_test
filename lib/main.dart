import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geiger_api/geiger_api.dart';
import 'geiger_api_connector/geiger_api_connector.dart';
import 'geiger_api_connector/sensor_node_model.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    log('Start building the application');
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
  String errorMessage = '';
  String userData = '';
  String deviceData = '';

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
          deviceNodeDataModel.sensorId, 'false');
      await pluginApiConnector.sendUserSensorData(
          userNodeDataModel.sensorId, '90');
    });
    final bool regPluginListener =
        await pluginApiConnector.registerPluginListener();

    // Prepare for storage event handler
    final bool regStorageListener =
        await pluginApiConnector.registerStorageListener(
            searchPath: ':',
            storageEventhandler:
                (EventType eventType, Node oldNode, Node newNode) {
              log('Received a storage change event');
              log(newNode.toString());
            });
    return regPluginListener && regStorageListener;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Geiger Toolbox"),
      ),
      body: Container(
        margin: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text('Built at: ${DateTime.now().toIso8601String()}'),
              const Divider(),
              const SizedBox(height: 5),
              const Text('Master Plugin'),
              ElevatedButton(
                onPressed: () async {
                  final bool masterPlugin = await initMasterPlugin();
                  if (masterPlugin == false) {
                    setState(() {
                      errorMessage = 'Failed to init Master Plugin';
                    });
                  }
                },
                child: const Text('Init GeigerAPI Master'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange,
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () async {
                  await masterApiConnector
                      .sendPluginEventType(MessageType.scanPressed);
                },
                child: const Text('Send SCAN_PRESSED'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange,
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
              // ElevatedButton(
              //   onPressed: () {
              //     final List<Message> allMessages =
              //         masterApiConnector.getAllPluginEvents();
              //     log('Number of messages: ${allMessages.length}');
              //     for (var i = 0; i < allMessages.length; i++) {
              //       final Message msg = allMessages[i];
              //       // String payloadText = msg.payloadString ?? '<empty>';
              //       // if (msg.payloadString!.isNotEmpty) {
              //       //   payloadText = utf8.decode(msg.payload);
              //       // }
              //       log('Message type: ${msg.type.toString()}');
              //       log(msg.toString());
              //       // log(payloadText);
              //     }

              //     final List<EventChange> allStorageEvents =
              //         masterApiConnector.getAllStorageEvents();
              //     log('Number of Storage Event: ${allStorageEvents.length}');
              //     for (var i = 0; i < allStorageEvents.length; i++) {
              //       final EventChange event = allStorageEvents[i];
              //       // String payloadText = msg.payloadString ?? '<empty>';
              //       // if (msg.payloadString!.isNotEmpty) {
              //       //   payloadText = utf8.decode(msg.payload);
              //       // }
              //       log('Event type: ${event.type}');
              //       // log(payloadText);
              //     }
              //   },
              //   child: const Text('View received events'),
              // ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () async {
                  await masterApiConnector.dumpLocalStorage();
                },
                child: const Text('Dump Storage'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange,
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
              // Card(
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       ElevatedButton(
              //         onPressed: () async {
              //           String? newUserData = await masterApiConnector
              //               .readGeigerValueOfUserSensor(
              //                   montimagePluginId, userNodeDataModel.sensorId);
              //           String? newDeviceData = await masterApiConnector
              //               .readGeigerValueOfDeviceSensor(montimagePluginId,
              //                   deviceNodeDataModel.sensorId);
              //           setState(() {
              //             userData = newUserData ?? userData;
              //             deviceData = newDeviceData ?? deviceData;
              //           });
              //         },
              //         child: const Text('Refresh Data'),
              //       ),
              //       Column(
              //         children: [
              //           Text('User data: $userData'),
              //           Text('Device data: $deviceData'),
              //         ],
              //       ),
              //     ],
              //   ),
              // ),
              const Divider(),
              const SizedBox(height: 5),
              const Text('External Plugin'),
              ElevatedButton(
                onPressed: () async {
                  final bool externalPlugin = await initExternalPlugin();
                  if (externalPlugin == false) {
                    setState(() {
                      errorMessage = 'Failed to init External Plugin';
                    });
                  }
                },
                child: const Text('Init GeigerAPI Plugin'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () async {
                  final bool dataSent =
                      await pluginApiConnector.sendDeviceSensorData(
                          deviceNodeDataModel.sensorId, "true");
                  if (dataSent == false) {
                    setState(() {
                      errorMessage = 'Failed to send data';
                    });
                  }
                },
                child: const Text('Send a device data'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () async {
                  final bool dataSent = await pluginApiConnector
                      .sendUserSensorData(userNodeDataModel.sensorId, "50");
                  if (dataSent == false) {
                    setState(() {
                      errorMessage = 'Failed to send data';
                    });
                  }
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
                  await pluginApiConnector
                      .sendPluginEventType(MessageType.scanCompleted);
                },
                child: const Text('Send SCAN_COMPLETED event'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
              // const SizedBox(height: 5),
              // ElevatedButton(
              //   onPressed: () async {
              //     // trigger/send a STORAGE_EVENT event
              //     await pluginApiConnector
              //         .sendPluginEventType(MessageType.storageEvent);
              //   },
              //   child: const Text('Send STORAGE_EVENT event'),
              // ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () async {
                  // trigger/send a STORAGE_EVENT event
                  await pluginApiConnector.sendDataNode(
                      ':Chatbot:sensors:$montimagePluginId:my-sensor-data',
                      ['category', 'isSubmitted', 'threatInfo'],
                      ['Malware', 'false', 'This is the threat info']);
                },
                child: const Text('Send a threat info to Chatbot'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () async {
                  pluginApiConnector.close();
                },
                child: const Text('Disconnect'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
