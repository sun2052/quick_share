import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_share/page/chatDetailPage.dart';
import 'package:quick_share/provider/chatsProvider.dart';
import 'package:quick_share/util/utils.dart';

class ChatsPage extends ConsumerWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var themeData = Theme.of(context);
    var chats = ref.watch(chatsProvider).values.toList().reversed;
    var tiles = ListTile.divideTiles(
      context: context,
      tiles: chats.map((e) {
        var latest = e.messages.values.last;
        var subtitle = latest is TextMessage ? latest.content : '[${(latest as DataMessage).name}]';
        return ListTile(
          leading: avatarIcon(deviceIconData(e.contact.device), themeData),
          title: Text(e.contact.name),
          subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(formatDateOrTime(latest.time), style: const TextStyle(color: Colors.grey)),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailPage(e.contact))),
        );
      }),
    ).toList();
    return Scaffold(
      body: ListView(children: tiles),
    );
  }
}
