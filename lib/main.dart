import 'dart:async';
import 'dart:developer';
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
  bool isInProcessing = false;
  bool isMasterStarted = false;
  bool isExternalPluginStarted = false;

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
          deviceNodeDataModel.sensorId, 'false');
      await pluginApiConnector.sendUserSensorData(
          userNodeDataModel.sensorId, '90');
    });
    final bool regPluginListener =
        await pluginApiConnector.registerPluginListener();

    // Prepare for storage event handler
    final bool regStorageListener =
        await pluginApiConnector.registerStorageListener();
    isExternalPluginStarted = true;
    return regPluginListener && regStorageListener;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Geiger API Test - ${DateTime.now().toString()}",
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 14,
            )),
      ),
      body: isInProcessing == true
          ? const Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.orange,
              ),
            )
          : Container(
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
                    isMasterStarted
                        ? Column(
                            children: [
                              const SizedBox(height: 5),
                              ElevatedButton(
                                onPressed: () async {
                                  setState(() {
                                    isInProcessing = true;
                                  });
                                  final bool sentScanPressed =
                                      await masterApiConnector
                                          .sendPluginEventType(
                                              MessageType.scanPressed);
                                  if (sentScanPressed == false) {
                                    log('Failed to send SCAN_PRESSED event');
                                    setState(() {
                                      errorMessage =
                                          'Failed to send SCAN_PRESSED event';
                                    });
                                  } else {
                                    SnackBar snackBar = const SnackBar(
                                      content: Text(
                                          'A SCAN_PRESSED event has been sent'),
                                    );
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(snackBar);
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
                                  await masterApiConnector.dumpLocalStorage();
                                },
                                child: const Text('Dump Storage'),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.orange,
                                  minimumSize: const Size.fromHeight(40),
                                ),
                              ),
                            ],
                          )
                        : Column(children: [
                            ElevatedButton(
                              onPressed: () async {
                                setState(() {
                                  isInProcessing = true;
                                });
                                final bool masterPlugin =
                                    await initMasterPlugin();
                                if (masterPlugin == false) {
                                  setState(() {
                                    errorMessage =
                                        'Failed to init Master Plugin';
                                  });
                                } else {
                                  SnackBar snackBar = const SnackBar(
                                    content: Text(
                                        'The External Plugin has been intialized successfully'),
                                  );
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                }
                                setState(() {
                                  isInProcessing = false;
                                });
                              },
                              child: const Text('Init GeigerAPI Master'),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.orange,
                                minimumSize: const Size.fromHeight(40),
                              ),
                            ),
                            const Text(
                                'The Master Plugin is not intialized yet!'),
                          ]),
                    const SizedBox(height: 10),
                    const Divider(
                      thickness: 5,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'External Plugin',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue),
                    ),
                    isExternalPluginStarted
                        ? Column(
                            children: [
                              const SizedBox(height: 5),
                              ElevatedButton(
                                onPressed: () async {
                                  setState(() {
                                    isInProcessing = true;
                                  });
                                  final bool dataSent = await pluginApiConnector
                                      .sendDeviceSensorData(
                                          deviceNodeDataModel.sensorId, "true");
                                  if (dataSent == false) {
                                    setState(() {
                                      errorMessage = 'Failed to send data';
                                    });
                                  } else {
                                    SnackBar snackBar = const SnackBar(
                                      content: Text('Data has been sent'),
                                    );
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(snackBar);
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
                                  final bool dataSent = await pluginApiConnector
                                      .sendUserSensorData(
                                          userNodeDataModel.sensorId, "50");
                                  if (dataSent == false) {
                                    setState(() {
                                      errorMessage = 'Failed to send data';
                                    });
                                  } else {
                                    SnackBar snackBar = const SnackBar(
                                      content: Text('Data has been sent'),
                                    );
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(snackBar);
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
                                      .sendPluginEventType(
                                          MessageType.scanCompleted);
                                  if (sentData == false) {
                                    setState(() {
                                      errorMessage =
                                          'Failed to send SCAN_COMPLETED';
                                    });
                                  } else {
                                    SnackBar snackBar = const SnackBar(
                                      content:
                                          Text('SCAN_COMPLETED has been sent'),
                                    );
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(snackBar);
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
                                    setState(() {
                                      errorMessage =
                                          'Failed to send data to Chatbot';
                                    });
                                  } else {
                                    SnackBar snackBar = const SnackBar(
                                      content: Text(
                                          'A Data has been sent to Chatbot'),
                                    );
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(snackBar);
                                  }
                                  setState(() {
                                    isInProcessing = false;
                                  });
                                },
                                child:
                                    const Text('Send a threat info to Chatbot'),
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
                          )
                        : Column(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  setState(() {
                                    isInProcessing = true;
                                  });
                                  final bool externalPlugin =
                                      await initExternalPlugin();
                                  if (externalPlugin == false) {
                                    setState(() {
                                      errorMessage =
                                          'Failed to init External Plugin';
                                    });
                                  } else {
                                    SnackBar snackBar = const SnackBar(
                                      content: Text(
                                          'The External Plugin has been intialized successfully'),
                                    );
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(snackBar);
                                  }
                                  setState(() {
                                    isInProcessing = false;
                                  });
                                },
                                child: const Text('Init GeigerAPI Plugin'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(40),
                                ),
                              ),
                              const Text(
                                  'The external plugin is not initialzed yet!'),
                            ],
                          )
                  ],
                ),
              ),
            ),
    );
  }
}
