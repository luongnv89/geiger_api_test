import 'dart:developer';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

class GeigerConnector {
  late GeigerApi? geigerApi;
  late StorageController? geigerToolboxStorageController;
  Future<void> initGeigerStorage() async {
    try {
      geigerApi = await getGeigerApi('<unspecified>', 'miCyberrangePlugin');
      geigerToolboxStorageController = geigerApi!.getStorage();
    } on Exception catch (e) {
      log('Cannot initialize GeigerAPI');
      log(e.toString());
    }
  }

  Future<void> writeToGeigerStorage(String data) async {
    try {
      log('Found the data node - Going to write the data');
      Node node = await geigerToolboxStorageController!.get(':data-node');
      await node.addOrUpdateValue(NodeValueImpl('data', '$data'));
      await geigerToolboxStorageController!.update(node);
    } catch (e) {
      log(e.toString());
      log('Cannot find the data node - Going to create a new one');
      Node node = NodeImpl('data-node', '');
      await geigerToolboxStorageController!.addOrUpdate(node);
      await node.addOrUpdateValue(NodeValueImpl('data', '$data'));
      await geigerToolboxStorageController!.update(node);
    }
  }

  Future<String?> readDataFromGeigerStorage() async {
    log('Trying to get the data node');
    try {
      log('Found the data node - Going to get the data');
      Node node = await geigerToolboxStorageController!.get(':data-node');
      NodeValue? nValue = await node.getValue('data');
      if (nValue != null) {
        return nValue.value;
      } else {
        log('Failed to retrieve the node value');
      }
    } catch (e) {
      log('Failed to retrieve the data node');
      log(e.toString());
    }
    return null;
  }
}
