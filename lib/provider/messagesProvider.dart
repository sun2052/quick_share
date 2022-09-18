import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_share/provider/chatsProvider.dart';

final messagesProvider = Provider.autoDispose.family<List<Message>, String>((ref, address) {
  var messages = ref.watch(chatsProvider.select((chats) => chats[address]?.messages));
  return messages?.values.toList() ?? [];
});
