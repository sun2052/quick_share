import 'dart:typed_data';

import 'package:quick_share/util/constant.dart';

// +---------+-----------+-----------------+
// | Type(4) | Length(8) | Content(Length) |
// +---------+-----------+-----------------+
class MessageBuilder {
  int type = MESSAGE_UNKNOWN;
  int length = 0;
  int received = 0;

  final BytesBuilder _buffer = BytesBuilder(copy: false);

  void add(Uint8List event) {
    _buffer.add(event);
    if (type == MESSAGE_UNKNOWN && _buffer.length >= 12) {
      var data = _buffer.takeBytes();
      _buffer.add(data.sublist(12));
      var header = ByteData.sublistView(data, 0, 12);
      type = header.getInt32(0);
      length = header.getInt64(4);
      received = _buffer.length;
    } else {
      received += event.length;
    }
  }

  bool hasContent() {
    return type != MESSAGE_UNKNOWN && received >= length;
  }

  Uint8List takeContent() {
    if (received >= length) {
      var data = _buffer.takeBytes();
      type = MESSAGE_UNKNOWN;
      add(data.sublist(length));
      data = data.sublist(0, length);
      return data;
    }
    return Uint8List.fromList([]);
  }

  Uint8List takeBytes([int? length]) {
    if (length == null) {
      return _buffer.takeBytes();
    }
    if (_buffer.length >= length) {
      var data = _buffer.takeBytes();
      _buffer.add(data.sublist(length));
      return data.sublist(0, length);
    }
    return Uint8List.fromList([]);
  }
}
