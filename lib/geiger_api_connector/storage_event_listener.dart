import 'dart:developer';

import 'package:geiger_localstorage/geiger_localstorage.dart';

class StorageEventListener implements StorageListener {
  final List<EventChange> events = [];
  String pluginId;
  Function? storageEventHandler;
  StorageEventListener({required this.pluginId, this.storageEventHandler});
  @override
  Future<void> gotStorageChange(
      EventType event, Node? oldNode, Node? newNode) async {
    events.add(EventChange(event, oldNode, newNode));
    log("*** [$pluginId] receives a storage change event***");
    if (storageEventHandler != null) {
      return storageEventHandler!(event, oldNode, newNode);
    } else {
      print("\n*** [$pluginId] receives a storage change event***");
      print(oldNode);
      print(newNode);
      print(event);
      print('***\n');
    }
  }

  List<EventChange> getAllStorageEvents() {
    return events;
  }
}

class EventChange {
  final EventType type;
  final Node? oldNode;
  final Node? newNode;

  EventChange(this.type, this.oldNode, this.newNode);
  @override
  String toString() {
    return 'EventChange{type: $type, oldNode: $oldNode, newNode: $newNode}';
  }
}
