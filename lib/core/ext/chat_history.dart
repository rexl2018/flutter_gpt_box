import 'package:flutter/material.dart';
import 'package:flutter_chatgpt/data/model/chat/history.dart';
import 'package:flutter_chatgpt/data/res/build.dart';
import 'package:flutter_chatgpt/data/res/l10n.dart';
import 'package:flutter_chatgpt/data/res/ui.dart';
import 'package:flutter_chatgpt/view/widget/code.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

extension ChatHistoryShare on ChatHistory {
  Widget gen4Share(bool isDark) {
    final children = <Widget>[];
    for (final item in items) {
      children.add(Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: Colors.grey,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        child: Text(
          item.role.name,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ));
      children.add(UIs.height13);
      children.add(MarkdownBody(
        data: item.toMarkdown,
        extensionSet: md.ExtensionSet.commonMark,
        builders: {
          'code': CodeElementBuilder(
            brightness: isDark ? Brightness.dark : Brightness.light,
            isForCapture: true,
          ),
        },
      ));
      children.add(UIs.height13);
    }
    final widget = Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: isDark ? Colors.black : Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name ?? l10n.untitled,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          UIs.height13,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
          UIs.height13,
          Text(
            '${l10n.shareFrom} GPT Box v1.0.${Build.build}',
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
    return widget;
  }
}
