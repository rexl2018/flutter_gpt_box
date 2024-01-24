import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chatgpt/core/store.dart';

class StoreSwitch extends StatelessWidget {
  final StorePropertyBase<bool> prop;

  /// Exec before make change, after validator.
  final FutureOr<void> Function(bool)? callback;

  /// If return false, the switch will not change.
  final bool Function(bool)? validator;

  final bool updateLastModTime;

  const StoreSwitch({
    super.key,
    required this.prop,
    this.callback,
    this.validator,
    this.updateLastModTime = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: prop.listenable(),
      builder: (context, bool value, widget) {
        return Switch(
          value: value,
          onChanged: (value) async {
            if (validator?.call(value) == false) return;
            prop.put(value, updateLastModified: updateLastModTime);
            await callback?.call(value);
          },
        );
      },
    );
  }
}
