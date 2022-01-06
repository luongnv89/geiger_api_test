import 'dart:developer';

import 'package:geiger_api/geiger_api.dart';

class SimpleEventListener implements PluginListener {
  List<Message> events = [];

  final String _id;

  SimpleEventListener(this._id);

  @override
  void pluginEvent(GeigerUrl? url, Message msg) {
    events.add(msg);
    log('[Listener "$_id"] received a new event ${msg.type} (source: ${msg.sourceId}, target: ${msg.targetId}');
    log('Message: ${msg.toString()}');
    log('Total events: ${events.length.toString()} events');
  }

  List<Message> getEvents() {
    return events;
  }

  @override
  String toString() {
    String ret = '';
    ret += 'Eventlistener "$_id" contains {\r\n';
    getEvents().forEach((element) {
      ret += '  ${element.toString()}\r\n';
    });
    ret += '}\r\n';
    return ret;
  }
}
