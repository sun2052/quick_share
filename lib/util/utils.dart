import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:quick_share/util/constant.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String uuid() {
  return _uuid.v4();
}

String formatTime(int millis) {
  return DateFormat.Hms().format(DateTime.fromMillisecondsSinceEpoch(millis));
}

String formatDate(int millis) {
  return DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(millis));
}

String formatDateOrTime(int millis) {
  var now = DateTime.now();
  var dateTime = DateTime.fromMillisecondsSinceEpoch(millis);
  if (now.year == dateTime.year && now.month == dateTime.month && now.day == dateTime.day) {
    return DateFormat.Hms().format(dateTime);
  } else {
    return DateFormat.yMd().format(dateTime);
  }
}

String formatSize(int bytes) {
  var units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  double size = bytes.toDouble();
  int i = 0;
  while (size >= 1024) {
    size /= 1024;
    i++;
  }
  return '${NumberFormat('#.##').format(size)} ${units[i]}';
}

IconData deviceIconData(int code) {
  switch (code) {
    case DEVICE_DESKTOP:
      return Icons.computer;
    case DEVICE_MOBILE:
      return Icons.smartphone;
    default:
      return Icons.device_unknown;
  }
}

Widget avatarIcon(IconData iconData, ThemeData themeData) {
  return Icon(iconData, size: themeData.textTheme.headlineLarge!.fontSize, color: themeData.primaryColor);
}

Widget inlineIcon(IconData iconData, ThemeData themeData) {
  return Icon(iconData, size: themeData.textTheme.bodyMedium!.fontSize);
}

void showNotice(String content, BuildContext context, {IconData icon = Icons.info_outline, GestureTapCallback? action}) {
  var themeData = Theme.of(context);
  showSimpleNotification(
    Builder(builder: (context) {
      return ListTile(
        leading: Icon(icon, size: themeData.textTheme.headlineLarge!.fontSize),
        title: Text(content, style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: () {
          if (action != null) {
            action();
          }
          OverlaySupportEntry.of(context)?.dismiss();
        },
      );
    }),
    background: Colors.blue,
    duration: const Duration(seconds: 3),
    slideDismissDirection: DismissDirection.horizontal,
  );
}
