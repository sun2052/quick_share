import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_share/msg/controlMsg.dart';
import 'package:quick_share/msg/dataMsg.dart';
import 'package:quick_share/msg/textMsg.dart';
import 'package:quick_share/provider/chatsProvider.dart';
import 'package:quick_share/provider/contactsProvider.dart';
import 'package:quick_share/util/config.dart';
import 'package:quick_share/util/constant.dart';
import 'package:quick_share/util/deviceInfo.dart';
import 'package:quick_share/util/messageBuilder.dart';
import 'package:quick_share/util/utils.dart';

class DataUtil {
  static Map<String, RawDatagramSocket> broadcastSockets = {};
  static Map<String, Socket> connections = {};
  static Map<Socket, MessageBuilder> messageBuilders = {};
  static Map<String, File> sentFiles = {};
  static Map<String, File> receivedFiles = {};
  static Map<Socket, String> receivedMsgIds = {};
  static Map<Socket, IOSink> receivedSinks = {};

  static late WidgetRef _ref;
  static late RawDatagramSocket _udp;

  static void init(WidgetRef ref) async {
    DataUtil._ref = ref;

    ServerSocket.bind(InternetAddress.anyIPv4, PORT).then((serverSocket) {
      serverSocket.listen((socket) {
        var address = socket.remoteAddress.address;
        var builder = messageBuilders.putIfAbsent(socket, () => MessageBuilder());
        socket.listen((event) {
          builder.add(event);
          if (builder.type == MESSAGE_DATA_RESPONSE) {
            var sink = receivedSinks[socket];
            if (sink == null && builder.received >= UUID_LENGTH) {
              var bytes = builder.takeBytes(UUID_LENGTH);
              if (bytes.isNotEmpty) {
                var msgId = utf8.decode(bytes);
                receivedMsgIds[socket] = msgId;
                var file = receivedFiles[msgId];
                if (file != null) {
                  sink = file.openWrite();
                  receivedSinks[socket] = sink;
                }
              }
            }
            var msgId = receivedMsgIds[socket];
            if (sink != null && msgId != null) {
              sink.add(builder.takeBytes());
              _updateDataProgress(address, msgId, builder);
              if (builder.hasContent()) {
                sink.flush().then((_) => sink!.close());
                sink.done.then((_) {
                  var file = receivedFiles.remove(msgId);
                  file!.rename(file.path.replaceAll(RegExp('$TMP_SUFFIX\$'), ''));
                  _updateDataProgress(address, msgId, builder);
                  receivedMsgIds.remove(socket);
                  receivedSinks.remove(socket);
                  socket.close();
                });
              }
            }
            return;
          }
          while (builder.hasContent()) {
            var type = builder.type;
            var bytes = builder.takeContent();
            var content = utf8.decode(bytes);
            switch (type) {
              case MESSAGE_TEXT:
                TextMsg msg = TextMsg.fromJson(jsonDecode(content));
                ref.read(chatsProvider.notifier).add(address, TextMessage(msg.id, msg.time, STATUS_COMPLETED, true, msg.content));
                break;
              case MESSAGE_DATA:
                DataMsg msg = DataMsg.fromJson(jsonDecode(content));
                ref.read(chatsProvider.notifier).add(address, DataMessage(msg.id, msg.time, STATUS_PENDING, true, msg.name, msg.size, msg.modified));
                break;
              case MESSAGE_DATA_REQUEST:
                String msgId = utf8.decode(bytes);
                var file = sentFiles[msgId];
                if (file == null) {
                  send(address, MESSAGE_DATA_EXPIRED, utf8.encode(msgId));
                } else {
                  Socket.connect(address, PORT).then((socket) {
                    var length = file.lengthSync() + bytes.length;
                    var header = Uint8List(12);
                    header.buffer.asByteData()
                      ..setInt32(0, MESSAGE_DATA_RESPONSE)
                      ..setInt64(4, length);
                    socket.add(header);
                    socket.add(bytes);
                    int sent = 0;
                    file.openRead().listen((event) {
                      socket.add(event);
                      sent += event.length;
                      _ref.read(chatsProvider.notifier).updateDataProgress(address, msgId, STATUS_TRANSFERRING, sent * 100 ~/ length);
                    }, onDone: () {
                      _ref.read(chatsProvider.notifier).updateDataProgress(address, msgId, STATUS_COMPLETED, 0);
                      socket.close();
                    });
                  });
                }
                break;
              case MESSAGE_DATA_EXPIRED:
                _ref.read(chatsProvider.notifier).updateDataProgress(address, content, STATUS_EXPIRED, 0);
                break;
            }
          }
        }, onDone: () => socket.close());
      });
    });

    _udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, PORT);
    _udp.listen((e) {
      Datagram? packet = _udp.receive();
      if (packet == null) {
        return;
      }
      ControlMsg msg = ControlMsg.fromJson(jsonDecode(utf8.decode(packet.data)));
      if (msg.id == DeviceInfo.deviceId) {
        return;
      }
      var address = packet.address.address;
      switch (msg.type) {
        case BROADCAST_DISCOVER:
          _addContact(address, msg);
          var data = utf8.encode(jsonEncode(ControlMsg(BROADCAST_RESPONSE, DeviceInfo.deviceId, DeviceInfo.deviceName, DeviceInfo.deviceType)));
          var sent = _udp.send(data, InternetAddress(address), PORT);
          break;
        case BROADCAST_RESPONSE:
          _addContact(address, msg);
          break;
        case BROADCAST_QUIT:
          _removeContact(address);
          break;
      }
    });

    var interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    for (var interface in interfaces) {
      var address = interface.addresses.first;
      if (!broadcastSockets.containsKey(address.address)) {
        var udp = await RawDatagramSocket.bind(address, 0);
        udp.broadcastEnabled = true;
        broadcastSockets[address.address] = udp;
      }
    }

    discover();
  }

  static bool sendTextMessage(String address, String content) {
    var msg = TextMsg(uuid(), DateTime.now().millisecondsSinceEpoch, content);
    var succeeded = send(address, MESSAGE_TEXT, utf8.encode(jsonEncode(msg)));
    if (succeeded) {
      _ref.read(chatsProvider.notifier).add(address, TextMessage(msg.id, msg.time, STATUS_COMPLETED, false, content));
    }
    return succeeded;
  }

  static bool sendDataMessage(String address, File file) {
    var name = file.uri.pathSegments.last;
    var size = file.lengthSync();
    var modified = file.lastModifiedSync().millisecondsSinceEpoch;
    var msg = DataMsg(uuid(), DateTime.now().millisecondsSinceEpoch, name, size, modified);
    var succeeded = send(address, MESSAGE_DATA, utf8.encode(jsonEncode(msg)));
    if (succeeded) {
      sentFiles[msg.id] = file;
      _ref.read(chatsProvider.notifier).add(address, DataMessage(msg.id, msg.time, STATUS_PENDING, false, name, size, modified));
    }
    return succeeded;
  }

  static bool sendDataRequest(String address, String msgId, File tmpFile) {
    var succeeded = send(address, MESSAGE_DATA_REQUEST, utf8.encode(msgId));
    if (succeeded) {
      receivedFiles[msgId] = tmpFile;
    }
    return succeeded;
  }

  static bool send(String address, int type, List<int> data) {
    var socket = connections[address];
    if (socket == null) {
      return false;
    }
    var header = Uint8List(12);
    header.buffer.asByteData()
      ..setInt32(0, type)
      ..setInt64(4, data.length);
    socket
      ..add(header)
      ..add(data)
      ..flush();
    return true;
  }

  static void discover() {
    _clearContacts();
    _broadcast(BROADCAST_DISCOVER);
  }

  static void quit() {
    _broadcast(BROADCAST_QUIT);
  }

  static void _broadcast(int broadcastType) {
    var data = utf8.encode(jsonEncode(ControlMsg(broadcastType, DeviceInfo.deviceId, DeviceInfo.deviceName, DeviceInfo.deviceType)));
    var address = InternetAddress(BROADCAST);
    for (var udp in broadcastSockets.values) {
      var sent = udp.send(data, address, PORT);
    }
  }

  static void _addContact(String address, ControlMsg message) {
    _ref.read(contactsProvider.notifier).add(address, message.name, message.device);
    if (!connections.containsKey(address)) {
      Socket.connect(address, PORT).then((socket) {
        if (!connections.containsKey(address)) {
          connections[address] = socket;
          socket.listen((e) {}, onDone: () => _removeContact(address));
        } else {
          socket.close();
        }
      });
    }
  }

  static void _removeContact(String address) {
    _ref.read(contactsProvider.notifier).remove(address);
    connections.remove(address)?.close();
  }

  static void _clearContacts() {
    _ref.read(contactsProvider.notifier).clear();
  }

  static void _updateDataProgress(String address, String msgId, MessageBuilder builder) {
    int progress = builder.received * 100 ~/ builder.length;
    int status = progress >= 100 ? STATUS_COMPLETED : STATUS_TRANSFERRING;
    _ref.read(chatsProvider.notifier).updateDataProgress(address, msgId, status, progress);
  }
}
