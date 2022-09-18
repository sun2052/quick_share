import 'package:flutter_riverpod/flutter_riverpod.dart';

class Contact {
  String address;
  String name;
  int device;

  Contact(this.address, this.name, this.device);
}

class ContactsNotifier extends StateNotifier<Map<String, Contact>> {
  ContactsNotifier() : super({});

  void add(String address, String name, int device) {
    state = Map.of(state..[address] = Contact(address, name, device));
  }

  void remove(String address) {
    state = Map.of(state..remove(address));
  }

  void clear() {
    state = {};
  }
}

final contactsProvider = StateNotifierProvider<ContactsNotifier, Map<String, Contact>>((ref) => ContactsNotifier());
