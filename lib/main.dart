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

const String montimagePluginId = 'this-is-my-stupid-plugin';

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
      sensorId: '123e4567-e89b-42d3-a456-556642440sdk-m100',
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
    final bool registerListener = await masterApiConnector.registerListener();
    return registerListener;
  }

  Future<bool> initExternalPlugin() async {
    final bool initGeigerAPI = await pluginApiConnector.connectToGeigerAPI();
    if (initGeigerAPI == false) return false;
    bool initLocalStorage = await pluginApiConnector.connectToLocalStorage();
    if (initLocalStorage == false) return false;
    initLocalStorage = await pluginApiConnector.prepareDeviceSensorRoot();
    if (initLocalStorage == false) return false;
    initLocalStorage = await pluginApiConnector.prepareUserSensorRoot();
    if (initLocalStorage == false) return false;
    initLocalStorage =
        await pluginApiConnector.addDeviceSensorNode(deviceNodeDataModel);
    if (initLocalStorage == false) return false;
    initLocalStorage =
        await pluginApiConnector.addUserSensorNode(userNodeDataModel);
    if (initLocalStorage == false) return false;
    pluginApiConnector.addMessagehandler(MessageType.scanPressed,
        (Message msg) async {
      await pluginApiConnector.sendDeviceSensorData(
          deviceNodeDataModel.sensorId, 'false');
      await pluginApiConnector.sendUserSensorData(
          userNodeDataModel.sensorId, '90');
    });
    final bool registerListener = await pluginApiConnector.registerListener();
    return registerListener;
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
            children: [
              Text('Built at: ${DateTime.now().toIso8601String()}'),
              const Divider(),
              const SizedBox(height: 10),
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
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await masterApiConnector
                      .sendAMessageType(MessageType.scanPressed);
                },
                child: const Text('Send SCAN_PRESSED'),
              ),
              Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        String? newUserData = await masterApiConnector
                            .readGeigerValueOfUserSensor(
                                montimagePluginId, userNodeDataModel.sensorId);
                        String? newDeviceData = await masterApiConnector
                            .readGeigerValueOfDeviceSensor(montimagePluginId,
                                deviceNodeDataModel.sensorId);
                        setState(() {
                          userData = newUserData ?? userData;
                          deviceData = newDeviceData ?? deviceData;
                        });
                      },
                      child: const Text('Refresh Data'),
                    ),
                    Column(
                      children: [
                        Text('User data: $userData'),
                        Text('Device data: $deviceData'),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: 10),
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
              ),
              const SizedBox(height: 10),
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
              ),
              const SizedBox(height: 10),
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
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  pluginApiConnector.close();
                },
                child: const Text('Disconnect'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  // trigger/send a SCAN_COMPLETED event
                  await pluginApiConnector
                      .sendAMessageType(MessageType.scanCompleted);
                },
                child: const Text('Send SCAN_COMPLETED event'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  // trigger/send a STORAGE_EVENT event
                  await pluginApiConnector
                      .sendAMessageType(MessageType.storageEvent);
                },
                child: const Text('Send STORAGE_EVENT event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
