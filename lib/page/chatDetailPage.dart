import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_share/provider/chatsProvider.dart';
import 'package:quick_share/provider/contactsProvider.dart';
import 'package:quick_share/provider/messagesProvider.dart';
import 'package:quick_share/util/config.dart';
import 'package:quick_share/util/constant.dart';
import 'package:quick_share/util/dataUtil.dart';
import 'package:quick_share/util/utils.dart';

class ChatDetailPage extends ConsumerWidget {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _editingController = TextEditingController();
  final Contact _contact;

  ChatDetailPage(this._contact, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var themeData = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_contact.name), centerTitle: true),
      body: Column(children: [
        Expanded(
          child: Material(
            child: Consumer(builder: ((context, ref, _) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
              });
              var messages = ref.watch(messagesProvider(_contact.address));
              return ListView.builder(
                padding: const EdgeInsets.all(10),
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return _renderMessage(messages[index], themeData, context);
                },
              );
            })),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          decoration: BoxDecoration(color: Colors.grey.withAlpha(50)),
          child: Row(children: [
            Ink(
              width: 60,
              decoration: ShapeDecoration(color: themeData.primaryColor, shape: const CircleBorder()),
              child: IconButton(
                tooltip: 'Send File',
                icon: const Icon(Icons.file_upload),
                color: Colors.white,
                splashRadius: 30,
                onPressed: () {
                  FilePicker.platform.pickFiles().then((result) {
                    if (result != null) {
                      File file = File(result.files.single.path!);
                      if (DataUtil.sendDataMessage(_contact.address, file)) {
                        _scrollToLast();
                      } else {
                        _showUnavailableMsg(context);
                      }
                    }
                  });
                },
              ),
            ),
            Expanded(
              child: TextField(
                controller: _editingController,
                decoration: const InputDecoration(
                  hintText: 'Write message...',
                  fillColor: Colors.white,
                  filled: true,
                ),
                minLines: 1,
                maxLines: 10,
              ),
            ),
            Ink(
              width: 60,
              decoration: ShapeDecoration(color: themeData.primaryColor, shape: const CircleBorder()),
              child: IconButton(
                tooltip: 'Send Message',
                icon: const Icon(Icons.send),
                color: Colors.white,
                splashRadius: 30,
                onPressed: () {
                  if (_editingController.text.isEmpty) {
                    return;
                  }
                  if (DataUtil.sendTextMessage(_contact.address, _editingController.text)) {
                    _editingController.clear();
                    _scrollToLast();
                  } else {
                    _showUnavailableMsg(context);
                  }
                },
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _scrollToLast() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
    );
  }

  void _showUnavailableMsg(BuildContext context) {
    _showErrorMsg('"${_contact.name}" Unavailable', context);
  }

  void _showErrorMsg(String msg, BuildContext context) {
    showNotice(msg, context, icon: Icons.error_outline);
  }

  Widget _renderMessage(Message message, ThemeData themeData, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5, bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [inlineIcon(message.incoming ? Icons.call_received : Icons.call_made, themeData), Text(DateTime.fromMillisecondsSinceEpoch(message.time).toString())]),
          Ink(
            color: Colors.lightGreen.shade400,
            child: InkWell(
              splashColor: Colors.lightGreen.shade900,
              child: Container(
                padding: const EdgeInsets.all(10),
                child: message is TextMessage ? _renderTextMessage(message, themeData) : _renderDataMessage(message as DataMessage, themeData),
              ),
              onTap: () {
                if (message is TextMessage) {
                  Clipboard.setData(ClipboardData(text: message.content));
                  _showErrorMsg('Message Copied', context);
                } else {
                  if (message.incoming) {
                    FilePicker.platform.getDirectoryPath().then((selectedDirectory) {
                      if (selectedDirectory != null) {
                        var fileName = (message as DataMessage).name;
                        if (File('$selectedDirectory/$fileName').existsSync()) {
                          _showErrorMsg('File Already Exists', context);
                          return null;
                        }
                        File tmpFile = File('$selectedDirectory/$fileName$TMP_SUFFIX');
                        if (tmpFile.existsSync()) {
                          _showErrorMsg('File Transfer In Progress', context);
                          return null;
                        }
                        bool succeeded = DataUtil.sendDataRequest(_contact.address, message.id, tmpFile);
                        if (!succeeded) {
                          _showUnavailableMsg(context);
                        }
                      }
                    });
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderTextMessage(TextMessage message, ThemeData themeData) {
    return Text(message.content, style: themeData.textTheme.bodyLarge);
  }

  Widget _renderDataMessage(DataMessage message, ThemeData themeData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.name, maxLines: 10, overflow: TextOverflow.ellipsis, style: themeData.textTheme.bodyLarge),
              Text('Size: ${formatSize(message.size)}'),
              Text('Modified: ${DateTime.fromMillisecondsSinceEpoch(message.modified).toString()}'),
              Text('Status: ${_buildStatusText(message)}'),
            ],
          ),
        ),
        avatarIcon(message.incoming ? Icons.download : Icons.upload, themeData),
      ],
    );
  }

  String _buildStatusText(DataMessage message) {
    switch (message.status) {
      case STATUS_PENDING:
        return 'Pending';
      case STATUS_TRANSFERRING:
        return 'Transferring ${message.progress}%';
      case STATUS_COMPLETED:
        return 'Completed';
      default:
        return 'Expired';
    }
  }
}
