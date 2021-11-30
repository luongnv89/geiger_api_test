import 'dart:developer';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

class GeigerConnector {
  late GeigerApi? geigerApi;
  late StorageController? storageController;

  Future<void> initGeigerAPI() async {
    try {
      flushGeigerApiCache();
      geigerApi = await getGeigerApi(
          '', GeigerApi.masterId, Declaration.doNotShareData);
      // geigerApi = await getGeigerApi(
      //     '', 'miCyberrangePlugin', Declaration.doNotShareData);
      if (geigerApi != null) {
        storageController = geigerApi!.getStorage();
        if (storageController == null) {
          log('Could not get the storageController');
        }
      } else {
        log('Could not get the GeigerAPI');
      }
    } catch (e) {
      log('Failed to get the GeigerAPI');
      log(e.toString());
    }
  }

  Future<void> writeToGeigerStorage(String data) async {
    try {
      log('Found the data node - Going to write the data');
      Node node = await storageController!.get(':data-node');
      await node.updateValue(NodeValueImpl('data', '$data'));
      await storageController!.update(node);
    } catch (e) {
      log(e.toString());
      log('Cannot find the data node - Going to create a new one');
      Node node = NodeImpl('data-node', '');
      await node.addValue(NodeValueImpl('data', '$data'));
      await storageController!.add(node);
    }
  }

  Future<String?> readDataFromGeigerStorage() async {
    log('Trying to get the data node');
    try {
      log('Found the data node - Going to get the data');
      Node node = await storageController!.get(':data-node');
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
