import 'dart:developer';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'sensor_node_model.dart';

import 'geiger_event_listener.dart';

class GeigerApiConnector {
  GeigerApiConnector({
    required this.pluginId,
  });

  String pluginId; // Unique and assigned by GeigerToolbox
  GeigerApi? pluginApi;
  StorageController? storageController;

  String? currentUserId; // will be retrieved from GeigerStorage
  String? currentDeviceId; // will be retrieved from GeigerStorage

  GeigerEventListener? pluginListener;
  List<MessageType> handledEvents = [];
  bool isListenerRegistered = false;

  Future<void> close() async {
    // if (storageController != null) {
    //   try {
    //     await storageController!.close();
    //   } catch (e) {
    //     log('Failed to close the Storage Controller');
    //     log(e.toString());
    //   }
    // }

    if (pluginApi != null) {
      try {
        await pluginApi!.close();
      } catch (e) {
        log('Failed to close the GeigerAPI');
        log(e.toString());
      }
    }
  }

  // Get an instance of GeigerApi, to be able to start working with GeigerToolbox
  Future<bool> connectToGeigerAPI() async {
    log('Trying to connect to the GeigerApi');
    if (pluginApi != null) {
      log('Plugin $pluginId has been initialized');
      return true;
    } else {
      try {
        flushGeigerApiCache();
        if (pluginId == GeigerApi.masterId) {
          pluginApi =
              await getGeigerApi('', pluginId, Declaration.doNotShareData);
          log('MasterId: ${pluginApi.hashCode}');
          return true;
        } else {
          pluginApi = await getGeigerApi(
              './$pluginId', pluginId, Declaration.doNotShareData);
          log('pluginApi: ${pluginApi.hashCode}');
          return true;
        }
      } catch (e) {
        log('Failed to get the GeigerAPI');
        log(e.toString());
        return false;
      }
    }
  }

  // Get UUID of user or device
  Future getUUID(var key) async {
    var local = await storageController!.get(':Local');
    var temp = await local.getValue(key);
    return temp?.getValue('en');
  }

  // Get an instance of GeigerStorage to read/write data
  Future<bool> connectToLocalStorage() async {
    log('Trying to connect to the GeigerStorage');
    if (storageController != null) {
      log('Plugin $pluginId has already connected to the GeigerStorage (${storageController.hashCode})');
      return true;
    } else {
      try {
        storageController = pluginApi!.getStorage();
        log('Connected to the GeigerStorage ${storageController.hashCode}');
        currentUserId = await getUUID('currentUser');
        currentDeviceId = await getUUID('currentDevice');
        log('currentUserId: $currentUserId');
        log('currentDeviceId: $currentDeviceId');
        return true;
      } catch (e) {
        log('Failed to connect to the GeigerStorage');
        log(e.toString());
        return false;
      }
    }
  }

  // Dynamically define the handler for each message type
  void addMessagehandler(MessageType type, Function handler) {
    if (pluginListener == null) {
      pluginListener = GeigerEventListener('PluginListener-$pluginId');
      log('PluginListener: ${pluginListener.hashCode}');
    }
    handledEvents.add(type);
    pluginListener!.addMessageHandler(type, handler);
  }

  // Register the listener to listen all messages (events)
  Future<bool> registerListener() async {
    if (isListenerRegistered == true) {
      log('Plugin ${pluginListener.hashCode} has been registered already!');
      return true;
    } else {
      if (pluginListener == null) {
        pluginListener = GeigerEventListener('PluginListener-$pluginId');
        log('PluginListener: ${pluginListener.hashCode}');
      }
      try {
        // await pluginApi!
        //     .registerListener(handledEvents, pluginListener!); // This should be correct one
        await pluginApi!
            .registerListener([MessageType.allEvents], pluginListener!);
        log('Plugin ${pluginListener.hashCode} has been registered and activated');
        isListenerRegistered = true;
        return true;
      } catch (e) {
        log('Failed to register listener');
        log(e.toString());
        return false;
      }
    }
  }

  // Send a simple message which contain only the message type to the GeigerToolbox
  Future<bool> sendAMessageType(MessageType messageType) async {
    try {
      log('Trying to send a message type $messageType');
      final GeigerUrl testUrl =
          GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
      final Message request = Message(
        pluginId,
        GeigerApi.masterId,
        messageType,
        testUrl,
      );
      await pluginApi!.sendMessage(request);
      log('A message type $messageType has been sent successfully');
      return true;
    } catch (e) {
      log('Failed to send a message type $messageType');
      log(e.toString());
      return false;
    }
  }

  // Show some statistics of Listener
  String getListenerToString() {
    return pluginListener.toString();
  }

  // Get the list of received messages
  List<Message> getAllMessages() {
    return pluginListener!.getAllMessages();
  }

  // Send some device sensor data to GeigerToolbox
  Future<bool> sendDeviceSensorData(String sensorId, String value) async {
    String nodePath =
        ':Device:$currentDeviceId:$pluginId:data:metrics:$sensorId';
    try {
      Node node = await storageController!.get(nodePath);
      node.addOrUpdateValue(NodeValueImpl('GEIGERValue', value));
      await storageController!.addOrUpdate(node);
      log('Updated node: ');
      log(node.toString());
      return true;
    } catch (e) {
      log('Failed to get node $nodePath');
      log(e.toString());
      return false;
    }
  }

  // Send some user sensor data to GeigerToolbox
  Future<bool> sendUserSensorData(String sensorId, String value) async {
    String nodePath = ':Users:$currentUserId:$pluginId:data:metrics:$sensorId';
    try {
      Node node = await storageController!.get(nodePath);
      node.addOrUpdateValue(NodeValueImpl('GEIGERValue', value));
      await storageController!.addOrUpdate(node);
      log('Updated node: ');
      log(node.toString());
      return true;
    } catch (e) {
      log('Failed to get node $nodePath');
      log(e.toString());
      return false;
    }
  }

  // Prepare the device sensor root
  Future<bool> prepareDeviceSensorRoot() async {
    log('Prepare sensor root for Device');
    try {
      await storageController!.addOrUpdate(
        NodeImpl('Device', '', ':'),
      );
      await storageController!.addOrUpdate(
        NodeImpl(currentDeviceId!, '', ':Device'),
      );
      await storageController!.addOrUpdate(
        NodeImpl(pluginId, '', ':Device:$currentDeviceId'),
      );
      await storageController!.addOrUpdate(
        NodeImpl('data', '', ':Device:$currentDeviceId:$pluginId'),
      );
      await storageController!.addOrUpdate(
        NodeImpl('metrics', '', ':Device:$currentDeviceId:$pluginId:data'),
      );
      log('Root Device has been prepared');
      Node testNode = await storageController!
          .get(':Device:$currentDeviceId:$pluginId:data:metrics');
      log('Root: ${testNode.toString()}');
      return true;
    } catch (e) {
      log('Failed to prepare the sensor root node Device');
      log(e.toString());
      return false;
    }
  }

  // Prepare the user sensor root
  Future<bool> prepareUserSensorRoot() async {
    log('Prepare sensor root for Users');
    try {
      await storageController!.addOrUpdate(
        NodeImpl('Users', '', ':'),
      );
      await storageController!.addOrUpdate(
        NodeImpl(currentUserId!, '', ':Users'),
      );
      await storageController!.addOrUpdate(
        NodeImpl(pluginId, '', ':Users:$currentUserId'),
      );
      await storageController!.addOrUpdate(
        NodeImpl('data', '', ':Users:$currentUserId:$pluginId'),
      );
      await storageController!.addOrUpdate(
        NodeImpl('metrics', '', ':Users:$currentUserId:$pluginId:data'),
      );
      log('Root Users has been prepared');
      Node testNode = await storageController!
          .get(':Users:$currentUserId:$pluginId:data:metrics');
      log('Root: ${testNode.toString()}');
      return true;
    } catch (e) {
      log('Failed to prepare the sensor root node Users');
      log(e.toString());
      return false;
    }
  }

  Future<bool> addUserSensorNode(SensorDataModel sensorDataModel) async {
    return await _addSensorNode(sensorDataModel, 'Users');
  }

  Future<bool> addDeviceSensorNode(SensorDataModel sensorDataModel) async {
    return await _addSensorNode(sensorDataModel, 'Device');
  }

  Future<bool> _addSensorNode(
      SensorDataModel sensorDataModel, String rootType) async {
    String rootPath =
        ':$rootType:${rootType == 'Users' ? currentUserId : currentDeviceId}:$pluginId:data:metrics';
    log('Before adding a sensor node ${sensorDataModel.sensorId}');
    try {
      Node node = NodeImpl(sensorDataModel.sensorId, '', rootPath);
      await node.addOrUpdateValue(
        NodeValueImpl('name', sensorDataModel.name),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('minValue', sensorDataModel.minValue),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('maxValue', sensorDataModel.maxValue),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('valueType', sensorDataModel.valueType),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('flag', sensorDataModel.flag),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('threatsImpact', sensorDataModel.threatsImpact),
      );
      log('A node has been craeted');
      log(node.toString());
      try {
        await storageController!.addOrUpdate(node);
        log('After adding a sensor node ${sensorDataModel.sensorId}');
        return true;
      } catch (e2) {
        log('Failed to update Storage');
        log(e2.toString());
        return false;
      }
    } catch (e) {
      log('Failed to add a sensor node ${sensorDataModel.sensorId}');
      log(e.toString());
      return false;
    }
  }

  Future<String?> readGeigerValueOfUserSensor(
      String _pluginId, String sensorId) async {
    return await _readValueOfNod(
        ':Users:$currentUserId:$_pluginId:data:metrics:$sensorId');
  }

  Future<String?> readGeigerValueOfDeviceSensor(
      String _pluginId, String sensorId) async {
    return await _readValueOfNod(
        ':Device:$currentDeviceId:$_pluginId:data:metrics:$sensorId');
  }

  Future<String?> _readValueOfNod(String nodePath) async {
    log('Going to get value of node at $nodePath');
    try {
      Node node = await storageController!.get(nodePath);
      var temp = await node.getValue('GEIGERValue');
      return temp?.getValue('en');
    } catch (e) {
      log('Failed to get value of node at $nodePath');
      log(e.toString());
    }
  }
}
