import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddressesNotifier extends StateNotifier<Set<String>> {
  AddressesNotifier() : super({}) {
    _updateAddresses();
    Connectivity().onConnectivityChanged.listen((result) => _updateAddresses());
  }

  void _updateAddresses() {
    NetworkInterface.list(type: InternetAddressType.IPv4).then((interfaces) {
      state = interfaces.map((e) => e.addresses).expand((e) => e.toList()).map((e) => e.address).toSet();
    });
  }
}

final addressesProvider = StateNotifierProvider<AddressesNotifier, Set<String>>((ref) => AddressesNotifier());
