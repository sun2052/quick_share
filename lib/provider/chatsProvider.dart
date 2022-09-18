import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_share/provider/contactsProvider.dart';

abstract class Message {
  String id;
  int time;
  int status;
  bool incoming;

  Message(this.id, this.time, this.status, this.incoming);
}

class TextMessage extends Message {
  String content;

  TextMessage(super.id, super.time, super.status, super.incoming, this.content);
}

class DataMessage extends Message {
  String name;
  int size;
  int modified;
  int progress = 0;

  DataMessage(super.id, super.time, super.status, super.incoming, this.name, this.size, this.modified);
}

class Chat {
  Contact contact;
  Map<String, Message> messages = {};

  Chat(this.contact);
}

class ChatsNotifier extends StateNotifier<Map<String, Chat>> {
  final Ref ref;

  ChatsNotifier(this.ref) : super({});

  void add(String address, Message message) {
    var contact = ref.read(contactsProvider)[address];
    if (contact == null) {
      return;
    }
    var chat = state.remove(address) ?? Chat(contact);
    chat.messages[message.id] = message;
    chat.messages = Map.of(chat.messages);
    state[address] = chat;
    state = Map.of(state);
  }

  void updateDataProgress(String address, String msgId, int status, int progress) {
    var chat = state[address];
    var message = chat?.messages[msgId];
    if (message is DataMessage) {
      if (message.status != status || message.progress != progress) {
        message.status = status;
        message.progress = progress;
        chat!.messages = Map.of(chat.messages);
        state = Map.of(state);
      }
    }
  }
}

final chatsProvider = StateNotifierProvider<ChatsNotifier, Map<String, Chat>>((ref) => ChatsNotifier(ref));
