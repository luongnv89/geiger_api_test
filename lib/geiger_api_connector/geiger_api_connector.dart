import 'dart:developer';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'sensor_node_model.dart';

import 'plugin_event_listener.dart';
import 'storage_event_listener.dart';

class GeigerApiConnector {
  GeigerApiConnector({
    required this.pluginId,
  });

  String pluginId; // Unique and assigned by GeigerToolbox
  GeigerApi? pluginApi;
  StorageController? storageController;

  String? currentUserId; // will be retrieved from GeigerStorage
  String? currentDeviceId; // will be retrieved from GeigerStorage

  PluginEventListener? pluginListener; // listen to Plugin Event
  bool isPluginListenerRegistered = false;
  List<MessageType> handledEvents = [];

  StorageEventListener? storageListener; // Listen to Storage Change event
  bool isStorageListenerRegistered = false;

  /// Close the geiger api properly
  Future<void> close() async {
    if (pluginApi != null) {
      try {
        await pluginApi!.close();
      } catch (e) {
        log('Failed to close the GeigerAPI');
        log(e.toString());
      }
    }
  }

  /// Get an instance of GeigerApi, to be able to start working with GeigerToolbox
  Future<bool> connectToGeigerAPI() async {
    log('Trying to connect to the GeigerApi');
    if (pluginApi != null) {
      log('Plugin $pluginId has been initialized');
      return true;
    } else {
      try {
        flushGeigerApiCache();
        if (pluginId == GeigerApi.masterId) {
          pluginApi = await getGeigerApi('', pluginId, Declaration.doShareData);
          log('MasterId: ${pluginApi.hashCode}');
          return true;
        } else {
          pluginApi = await getGeigerApi(
              './$pluginId', pluginId, Declaration.doShareData);
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

  /// Get UUID of user or device
  Future getUUID(var key) async {
    var local = await storageController!.get(':Local');
    var temp = await local.getValue(key);
    return temp?.getValue('en');
  }

  /// Get an instance of GeigerStorage to read/write data
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

  /// Get all storage change event from Storage Listener
  List<EventChange> getAllStorageEvents() {
    return storageListener!.events;
  }

  /// Dump local storage value into terminal
  Future<String> dumpLocalStorage(String? path) async {
    final String storageStr = await storageController!.dump(path ?? ':');
    log('Storage Contents:');
    log(storageStr);
    return storageStr;
    // Node demoExample02 = NodeImpl(':Local:DemoExample', '');
    // await demoExample02.addOrUpdateValue(NodeValueImpl('GEIGERValue', '100'));
    // log('Going to trigger some changes');
    // await storageController!.addOrUpdate(demoExample02);
  }

  /// Dynamically define the handler for each plugin event
  void addPluginEventhandler(MessageType type, Function handler) {
    if (pluginListener == null) {
      pluginListener = PluginEventListener('PluginListener-$pluginId');
      log('PluginListener: ${pluginListener.hashCode}');
    }
    handledEvents.add(type);
    pluginListener!.addPluginEventHandler(type, handler);
  }

  /// Register the storage listener
  Future<bool> registerStorageListener(
      {String? searchPath, Function? storageEventhandler}) async {
    if (isStorageListenerRegistered == true) {
      log('The storage listener ${pluginListener.hashCode} has been registered already!');
      return true;
    } else {
      if (storageListener == null) {
        // Create a storage listener
        storageListener = StorageEventListener(
            pluginId: pluginId, storageEventHandler: storageEventhandler);
        log('storageListener: ${storageListener.hashCode}');
      }
      try {
        SearchCriteria sc = SearchCriteria(searchPath: searchPath ?? ':');
        await storageController!.registerChangeListener(storageListener!, sc);
        log('StorageEventListener ${storageListener.hashCode} ($pluginId) has been registered');
        isStorageListenerRegistered = true;
        return true;
      } catch (e) {
        log('Failed to register a storage listener');
        log(e.toString());
        return false;
      }
    }
  }

  // Register the plugin listener
  Future<bool> registerPluginListener() async {
    if (isPluginListenerRegistered == true) {
      log('The plugin listener ${pluginListener.hashCode} has been registered already!');
      return true;
    } else {
      if (pluginListener == null) {
        pluginListener = PluginEventListener('PluginListener-$pluginId');
        log('PluginListener: ${pluginListener.hashCode}');
      }
      try {
        // await pluginApi!
        //     .registerListener(handledEvents, pluginListener!); // This should be correct one
        await pluginApi!
            .registerListener([MessageType.allEvents], pluginListener!);
        log('PluginListener ${pluginListener.hashCode} ($pluginId) has been registered and activated');
        isPluginListenerRegistered = true;
        return true;
      } catch (e) {
        log('Failed to register a plugin listener');
        log(e.toString());
        return false;
      }
    }
  }

  /// Send a simple Plugin Event which contain only the message type to the GeigerToolbox
  Future<bool> sendPluginEventType(MessageType messageType) async {
    try {
      log('Trying to send a message type $messageType');
      // final GeigerUrl testUrl = GeigerUrl.fromSpec(
      //     'geiger://${GeigerApi.masterId}/test'); // TODO: is that the testURL always like this?
      // pluginApi.scanButtonPressed();
      final Message request = Message(
        pluginId,
        GeigerApi.masterId,
        messageType,
        null,
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

  /// Show some statistics of Listener
  String getPluginListenerStats() {
    return pluginListener.toString();
  }

  /// Get the list of all plugin events
  List<Message> getAllPluginEvents() {
    return pluginListener!.getAllPluginEvents();
  }

  String showAllPluginEvents() {
    String ret = '';
    final List<Message> allEvents = pluginListener!.getAllPluginEvents();
    if (allEvents.isEmpty) return '<There is not any plugin event>';
    ret = 'Total number of Plugin events: ${allEvents.length}\n\n';
    for (var i = 0; i < allEvents.length; i++) {
      ret += allEvents[i].toString();
      ret += '\n-------\n';
    }
    return ret;
  }

  String showAllStorageEvents() {
    String ret = '';
    final List<EventChange> allEvents = storageListener!.getAllStorageEvents();
    if (allEvents.isEmpty) return '<There is not any storage event>';
    ret = 'Total number of storage events: ${allEvents.length}\n\n';
    for (var i = 0; i < allEvents.length; i++) {
      ret += allEvents[i].toString();
      ret += '\n-------\n';
    }
    return ret;
  }

  /// Send some device sensor data to GeigerToolbox
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

  /// Send some user sensor data to GeigerToolbox
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
      log('Failed to send a data node $nodePath');
      log(e.toString());
      return false;
    }
  }

  /// Prepare a root node with given path
  Future<bool> prepareRoot(List<String> rootPath, String? owner) async {
    String currentRoot = '';
    int currentIndex = 0;
    while (currentIndex < rootPath.length) {
      try {
        await storageController!.addOrUpdate(NodeImpl(rootPath[currentIndex],
            owner ?? '', currentRoot == '' ? ':' : currentRoot));
        currentRoot = '$currentRoot:${rootPath[currentIndex]}';
        currentIndex++;
      } catch (e) {
        log('Failed to prepare the path: $currentRoot:${rootPath[currentIndex]}');
        log(e.toString());
        return false;
      }
    }
    Node testNode = await storageController!.get(currentRoot);
    log('Root: ${testNode.toString()}');
    return true;
  }

  /// Send a data node which include creating a new node and write the data
  Future<bool> sendDataNode(
      String nodePath, List<String> keys, List<String> values) async {
    if (keys.length != values.length) {
      log('The size of keys and values must be the same');
      return false;
    }
    try {
      Node node = NodeImpl(nodePath, '');
      for (var i = 0; i < keys.length; i++) {
        await node.addValue(NodeValueImpl(keys[i], values[i]));
      }
      await storageController!.addOrUpdate(node);
      return true;
    } catch (e) {
      log('Failed to send a data node: $nodePath');
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
      log('A node has been created');
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

  /// Read a value of user sensor
  Future<String?> readGeigerValueOfUserSensor(
      String _pluginId, String sensorId) async {
    return await _readValueOfNode(
        ':Users:$currentUserId:$_pluginId:data:metrics:$sensorId');
  }

  /// Read a value of device sensor
  Future<String?> readGeigerValueOfDeviceSensor(
      String _pluginId, String sensorId) async {
    return await _readValueOfNode(
        ':Device:$currentDeviceId:$_pluginId:data:metrics:$sensorId');
  }

  Future<String?> _readValueOfNode(String nodePath) async {
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
