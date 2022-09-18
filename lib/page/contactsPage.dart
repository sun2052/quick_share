import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_share/page/chatDetailPage.dart';
import 'package:quick_share/provider/contactsProvider.dart';
import 'package:quick_share/util/dataUtil.dart';
import 'package:quick_share/util/utils.dart';

class ContactsPage extends ConsumerWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var themeData = Theme.of(context);
    var contacts = ref.watch(contactsProvider).values;
    var tiles = ListTile.divideTiles(
      context: context,
      tiles: contacts.map((e) => ListTile(
            leading: avatarIcon(deviceIconData(e.device), themeData),
            title: Text(e.name),
            subtitle: Text(e.address),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailPage(e))),
          )),
    ).toList();
    return Scaffold(
      body: ListView(children: tiles),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Discover',
        child: const Icon(Icons.wifi_tethering),
        onPressed: () {
          showSnackBar(const Text('Discovering Contacts...'), context);
          DataUtil.discover();
        },
      ),
    );
  }
}
