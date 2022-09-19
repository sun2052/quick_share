import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_share/util/dataUtil.dart';

class AddressesNotifier extends StateNotifier<Set<String>> {
  AddressesNotifier() : super({}) {
    _updateAddresses();
    Connectivity().onConnectivityChanged.listen((result) => _updateAddresses());
  }

  void _updateAddresses() {
    NetworkInterface.list(type: InternetAddressType.IPv4).then((interfaces) {
      state = interfaces.map((e) => e.addresses).expand((e) => e.toList()).map((e) => e.address).toSet();
      var addresses = interfaces.map((e) => e.addresses.first.address).toSet();
      DataUtil.broadcastSockets.removeWhere((key, value) => !addresses.contains(key));
      for (var address in addresses) {
        if (!DataUtil.broadcastSockets.containsKey(address)) {
          RawDatagramSocket.bind(address, 0).then((udp) {
            udp.broadcastEnabled = true;
            DataUtil.broadcastSockets[address] = udp;
          });
        }
      }
    });
  }
}

final addressesProvider = StateNotifierProvider<AddressesNotifier, Set<String>>((ref) => AddressesNotifier());
