/*
* Copyright (C) Keshav Priyadarshi and others - All Rights Reserved.
*
* SPDX-License-Identifier: GPL-3.0-or-later
* You may use, distribute and modify this code under the
* terms of the GPL-3.0+ license.
*
* You should have received a copy of the GNU General Public License v3.0 with
* this file. If not, please visit https://www.gnu.org/licenses/gpl-3.0.html
*
* See https://safenotes.dev for support or download.
*/

// Dart imports:
import 'dart:async';
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:easy_localization/easy_localization.dart';
import 'package:local_session_timeout/local_session_timeout.dart';

// Project imports:
import 'package:safenotes/data/database_handler.dart';
import 'package:safenotes/models/safenote.dart';

class ChecklistEditor extends StatefulWidget {
  final StreamController<SessionState> sessionStateStream;
  final SafeNote? note;

  const ChecklistEditor({
    super.key,
    required this.sessionStateStream,
    this.note,
  });

  @override
  State<ChecklistEditor> createState() => _ChecklistEditorState();
}

class _ChecklistEditorState extends State<ChecklistEditor> {
  final _titleController = TextEditingController();
  late List<_CheckItem> _items;
  final _focusNodes = <FocusNode>[];

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _items = _parseItems(widget.note!.description);
    } else {
      _items = [_CheckItem(text: '', checked: false)];
    }
    _syncFocusNodes();
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final fn in _focusNodes) {
      fn.dispose();
    }
    super.dispose();
  }

  List<_CheckItem> _parseItems(String description) {
    try {
      final list = jsonDecode(description) as List;
      return list
          .map((e) => _CheckItem(
                text: e['text'] as String? ?? '',
                checked: e['checked'] as bool? ?? false,
              ))
          .toList();
    } catch (_) {
      if (description.trim().isEmpty || description == ' ') {
        return [_CheckItem(text: '', checked: false)];
      }
      return description
          .split('\n')
          .map((l) => _CheckItem(text: l, checked: false))
          .toList();
    }
  }

  String _serializeItems() {
    return jsonEncode(
      _items.map((i) => {'text': i.text, 'checked': i.checked}).toList(),
    );
  }

  void _syncFocusNodes() {
    while (_focusNodes.length < _items.length) {
      _focusNodes.add(FocusNode());
    }
    while (_focusNodes.length > _items.length) {
      _focusNodes.removeLast().dispose();
    }
  }

  void _addItem(int afterIndex) {
    setState(() {
      _items.insert(afterIndex + 1, _CheckItem(text: '', checked: false));
      _syncFocusNodes();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (afterIndex + 1 < _focusNodes.length) {
        _focusNodes[afterIndex + 1].requestFocus();
      }
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items.removeAt(index);
      _syncFocusNodes();
    });
  }

  void _reorderItem(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final title = _titleController.text.isEmpty
        ? 'Checklist'.tr()
        : _titleController.text;

    final serialized = _serializeItems();

    if (widget.note != null) {
      final updated = widget.note!.copy(
        title: title,
        description: serialized,
        createdTime: DateTime.now(),
        contentFormat: 'plain',
      );
      await NotesDatabase.instance.encryptAndUpdate(updated);
    } else {
      final note = SafeNote(
        title: title,
        description: serialized,
        createdTime: DateTime.now(),
        noteType: 'checklist',
        contentFormat: 'plain',
      );
      await NotesDatabase.instance.encryptAndStore(note);
    }

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Checklist'.tr()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
              ),
              onPressed: _save,
              child: Text('Save'.tr(),
                style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextFormField(
              controller: _titleController,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Title'.tr(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _items.length,
              buildDefaultDragHandles: false,
              onReorder: _reorderItem,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _buildCheckItem(item, index, cs);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addCheckItem',
        onPressed: () => _addItem(_items.length - 1),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCheckItem(_CheckItem item, int index, ColorScheme cs) {
    return Dismissible(
      key: ValueKey('check_${item.hashCode}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeItem(index),
      background: Container(
        alignment: Alignment.centerRight,
        color: cs.error,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: cs.onError),
      ),
      child: ListTile(
        key: ValueKey('tile_$index'),
        leading: Checkbox(
          value: item.checked,
          onChanged: (val) {
            setState(() => _items[index] = item.copyWith(checked: val));
          },
        ),
        title: TextFormField(
          focusNode: index < _focusNodes.length ? _focusNodes[index] : null,
          initialValue: item.text,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
          ),
          style: TextStyle(
            fontSize: 16,
            decoration:
                item.checked ? TextDecoration.lineThrough : null,
            color: item.checked ? cs.outline : cs.onSurface,
          ),
          onChanged: (val) {
            _items[index] = item.copyWith(text: val);
          },
          onFieldSubmitted: (_) => _addItem(index),
        ),
        trailing: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
      ),
    );
  }
}

class _CheckItem {
  final String text;
  final bool checked;

  const _CheckItem({required this.text, required this.checked});

  _CheckItem copyWith({String? text, bool? checked}) => _CheckItem(
    text: text ?? this.text,
    checked: checked ?? this.checked,
  );
}
