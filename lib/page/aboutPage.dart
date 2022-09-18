import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_share/provider/addressesProvider.dart';
import 'package:quick_share/util/config.dart';
import 'package:quick_share/util/deviceInfo.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var themeData = Theme.of(context);
    var homePage = Uri.parse('https://github.com/sun2052/quick_share');
    return Scaffold(
      appBar: AppBar(title: const Text('About'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: Column(children: [
            Text('$APP_TITLE $APP_VERSION', style: TextStyle(fontSize: themeData.textTheme.headlineMedium!.fontSize, height: 2)),
            const Text('An Open Source AirDrop Alternative.'),
            TextButton(
              child: Text(homePage.toString()),
              onPressed: () async {
                if (!await launchUrl(homePage, mode: LaunchMode.externalApplication)) {
                  throw 'Could not launch $homePage';
                }
              },
            ),
            Text('Local Addresses', style: TextStyle(fontSize: themeData.textTheme.headlineMedium!.fontSize, height: 2)),
            Consumer(builder: (context, ref, _) {
              var addresses = ref.watch(addressesProvider);
              return Text(addresses.isEmpty ? "Loading..." : addresses.toString());
            }),
            Text('Device Info', style: TextStyle(fontSize: themeData.textTheme.headlineMedium!.fontSize, height: 2)),
            Center(
              child: Column(
                children: DeviceInfo.infoMap.entries
                    .map((e) => [
                          Text(e.key, style: const TextStyle(color: Colors.grey)),
                          Text(e.value),
                          Container(margin: const EdgeInsets.only(top: 5, bottom: 5), child: const Divider()),
                        ])
                    .expand((e) => e.toList())
                    .toList(),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
