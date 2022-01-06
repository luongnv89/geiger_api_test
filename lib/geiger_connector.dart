import 'dart:developer';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'simple_event_listener.dart';

class GeigerConnector {
  late GeigerApi? localMaster;
  late SimpleEventListener? masterListener;
  late StorageController? storageController;
  Future<void> initGeigerAPI() async {
    try {
      flushGeigerApiCache();
      // Init local master
      localMaster = await getGeigerApi(
          '', GeigerApi.masterId, Declaration.doNotShareData);
      if (localMaster != null) {
        await localMaster!.zapState();
        masterListener = SimpleEventListener('master');
        List<MessageType> allEvents = [MessageType.allEvents];
        await localMaster!.registerListener(allEvents, masterListener!);
        try {
          storageController = localMaster!.getStorage();
          if (storageController == null) {
            log('Could not get the storageController');
          }
        } catch (e2) {
          log('Failed to get the storage Controller');
          log(e2.toString());
        }
      } else {
        log('Could not get the GeigerAPI');
      }
    } catch (e) {
      log('Failed to get the GeigerAPI');
      log(e.toString());
    }
  }

  List<Message> getEvents() {
    return masterListener!.getEvents();
  }
}
