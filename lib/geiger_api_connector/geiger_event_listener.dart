import 'dart:developer';

import 'package:geiger_api/geiger_api.dart';

class GeigerEventListener implements PluginListener {
  int numberReceivedMessages = 0;
  int numberHandledMessages = 0;
  List<Message> messages = [];
  Map<MessageType, Function> messageHandler = {};
  final String _id;

  GeigerEventListener(this._id);

  /// Add a handler for a special message type
  /// If the message type has been handled by one handler, the old handler will be overwrided by the new one
  void addMessageHandler(MessageType type, Function handler) {
    messageHandler[type] = handler;
  }

  @override
  void pluginEvent(GeigerUrl? url, Message msg) {
    log('[Eventlistener "$_id"] received a new event ${msg.type} (source: ${msg.sourceId}, target: ${msg.targetId}');
    numberReceivedMessages++;
    messages.add(msg);
    Function? handler = messageHandler[msg.type];
    if (handler != null) {
      numberHandledMessages++;
      handler(msg);
    } else {
      log('Eventlistener $_id does not handle message type ${msg.type}');
    }
  }

  @override
  String toString() {
    String ret = '';
    ret +=
        'Eventlistener "$_id" has received $numberReceivedMessages messages\n';
    ret += 'Eventlistener "$_id" has handled $numberHandledMessages messages\n';
    ret +=
        'Eventlistener "$_id" has dropped ${numberReceivedMessages - numberHandledMessages} messages\n';
    return ret;
  }

  List<Message> getAllMessages() {
    return messages;
  }
}
