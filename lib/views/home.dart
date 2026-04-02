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

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:local_session_timeout/local_session_timeout.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:safenotes/data/database_handler.dart';
import 'package:safenotes/data/preference_and_config.dart';
import 'package:safenotes/dialogs/backup_import.dart';
import 'package:safenotes/models/safenote.dart';
import 'package:safenotes/models/session.dart';
import 'package:safenotes/routes/route_generator.dart';
import 'package:safenotes/utils/notes_color.dart';
import 'package:safenotes/widgets/advanced_fab.dart';
import 'package:safenotes/widgets/drawer.dart';
import 'package:safenotes/widgets/note_card.dart';
import 'package:safenotes/widgets/note_card_compact.dart';
import 'package:safenotes/widgets/note_color_picker.dart';
import 'package:safenotes/widgets/note_tile.dart';
import 'package:safenotes/widgets/note_tile_compact.dart';
import 'package:safenotes/widgets/search_widget.dart';

enum NoteSortMode {
  defaultView,
  createdDesc,
  createdAsc,
  modifiedDesc,
  modifiedAsc,
}

class HomePage extends StatefulWidget {
  final StreamController<SessionState> sessionStateStream;

  const HomePage({Key? key, required this.sessionStateStream})
    : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late List<SafeNote> notes;
  late List<SafeNote> allnotes;
  bool isLoading = false;
  String query = '';
  bool isHiddenImport = true;
  bool isGridView = PreferencesStorage.isGridView;
  final importPassphraseController = TextEditingController();

  bool _isSelectionMode = false;
  final Set<int> _selectedNoteIds = {};

  NoteSortMode _sortMode = NoteSortMode.values[
    PreferencesStorage.sortMode.clamp(0, NoteSortMode.values.length - 1)
  ];

  @override
  void initState() {
    super.initState();
    refreshNotes();
  }

  Future<void> refreshNotes() async {
    setState(() => isLoading = true);
    await _sortAndStoreNotes();
    setState(() => isLoading = false);
  }

  Future<void> _sortAndStoreNotes() async {
    final tmpNotes = await NotesDatabase.instance.decryptReadAllNotes();
    _applySortMode(tmpNotes);
    setState(() {
      allnotes = notes = tmpNotes;
    });
  }

  void _applySortMode(List<SafeNote> list) {
    switch (_sortMode) {
      case NoteSortMode.defaultView:
        list.sort((a, b) {
          final aOrder = a.sortOrder ?? 999999;
          final bOrder = b.sortOrder ?? 999999;
          if (aOrder != bOrder) return aOrder.compareTo(bOrder);
          return b.createdTime.compareTo(a.createdTime);
        });
        break;
      case NoteSortMode.createdDesc:
        list.sort((a, b) => b.createdTime.compareTo(a.createdTime));
        break;
      case NoteSortMode.createdAsc:
        list.sort((a, b) => a.createdTime.compareTo(b.createdTime));
        break;
      case NoteSortMode.modifiedDesc:
        list.sort((a, b) {
          final aMod = a.modifiedTime ?? a.createdTime;
          final bMod = b.modifiedTime ?? b.createdTime;
          return bMod.compareTo(aMod);
        });
        break;
      case NoteSortMode.modifiedAsc:
        list.sort((a, b) {
          final aMod = a.modifiedTime ?? a.createdTime;
          final bMod = b.modifiedTime ?? b.createdTime;
          return aMod.compareTo(bMod);
        });
        break;
    }
  }

  void _setSortMode(NoteSortMode mode) {
    setState(() => _sortMode = mode);
    PreferencesStorage.setSortMode(mode.index);
    _sortAndStoreNotes();
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedNoteIds.clear();
    });
  }

  void _toggleSelection(SafeNote note) {
    if (note.id == null) return;
    setState(() {
      if (_selectedNoteIds.contains(note.id)) {
        _selectedNoteIds.remove(note.id);
        if (_selectedNoteIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedNoteIds.add(note.id!);
      }
    });
  }

  void _enterSelectionMode(SafeNote note) {
    if (note.id == null) return;
    setState(() {
      _isSelectionMode = true;
      _selectedNoteIds.add(note.id!);
    });
  }

  void _selectAll() {
    setState(() {
      _selectedNoteIds.addAll(
        notes.where((n) => n.id != null).map((n) => n.id!),
      );
    });
  }

  Future<void> _bulkDelete() async {
    final count = _selectedNoteIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Notes'.tr()),
        content: Text('Delete $count selected notes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text('Delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NotesDatabase.instance.deleteMultiple(_selectedNoteIds.toList());
      _exitSelectionMode();
      await refreshNotes();
    }
  }

  Future<void> _bulkChangeColor() async {
    final colorIndex = await showNoteColorPicker(context);
    if (colorIndex == null) return;

    final ids = _selectedNoteIds.toList();
    final dbColorIndex = colorIndex == -1 ? null : colorIndex;
    await NotesDatabase.instance.updateColorIndex(ids, dbColorIndex);
    _exitSelectionMode();
    await refreshNotes();
  }

  void _onNoteTap(SafeNote note, int index) async {
    if (_isSelectionMode) {
      _toggleSelection(note);
      return;
    }
    await Navigator.pushNamed(
      context,
      '/viewnote',
      arguments: NoteDetailPageArguments(
        note: note,
        sessionStream: widget.sessionStateStream,
        noteIndex: index,
      ),
    );
    refreshNotes();
  }

  void _onNoteLongPress(SafeNote note) {
    if (!_isSelectionMode) {
      _enterSelectionMode(note);
    } else {
      _toggleSelection(note);
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    setState(() {
      final item = notes.removeAt(oldIndex);
      notes.insert(newIndex, item);
      allnotes = List.from(notes);
    });

    final idToOrder = <int, int>{};
    for (var i = 0; i < notes.length; i++) {
      final id = notes[i].id;
      if (id != null) idToOrder[id] = i;
    }
    await NotesDatabase.instance.updateSortOrder(idToOrder);

    if (_sortMode != NoteSortMode.defaultView) {
      _sortMode = NoteSortMode.defaultView;
      PreferencesStorage.setSortMode(NoteSortMode.defaultView.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<NotesColor>(context);

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: GestureDetector(
        onTap: dismissKeyboard,
        onVerticalDragStart: dismissKeyboard,
        onVerticalDragDown: dismissKeyboard,
        child: Scaffold(
          drawer: _isSelectionMode ? null : _buildDrawer(context),
          appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
          body: Column(children: [
            if (!_isSelectionMode) _buildSearch(),
            _handleAndBuildNotes(),
          ]),
          floatingActionButton: _isSelectionMode ? null : _addANewNoteButton(context),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      title: Text('Safe Notes'.tr()),
      actions: isLoading
          ? null
          : [
              _gridListView(),
              _buildSortButton(),
            ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
      title: Text('${_selectedNoteIds.length} ${'selected'.tr()}'),
      backgroundColor: cs.surfaceContainerHigh,
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: 'Select all'.tr(),
          onPressed: _selectAll,
        ),
        IconButton(
          icon: const Icon(Icons.palette_outlined),
          tooltip: 'Choose Color'.tr(),
          onPressed: _bulkChangeColor,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete'.tr(),
          onPressed: _bulkDelete,
        ),
      ],
    );
  }

  Widget _gridListView() {
    return IconButton(
      icon: !isGridView
          ? const Icon(Icons.grid_view_outlined)
          : const Icon(Icons.splitscreen_outlined),
      onPressed: () {
        setState(() {
          PreferencesStorage.setIsGridView(!isGridView);
          isGridView = !isGridView;
        });
      },
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<NoteSortMode>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort'.tr(),
      onSelected: _setSortMode,
      itemBuilder: (context) => [
        _sortMenuItem(NoteSortMode.defaultView, 'Default view'.tr(), Icons.dashboard_outlined),
        const PopupMenuDivider(),
        _sortMenuItem(NoteSortMode.createdDesc, 'Created: Newest first'.tr(), Icons.arrow_downward),
        _sortMenuItem(NoteSortMode.createdAsc, 'Created: Oldest first'.tr(), Icons.arrow_upward),
        const PopupMenuDivider(),
        _sortMenuItem(NoteSortMode.modifiedDesc, 'Modified: Newest first'.tr(), Icons.arrow_downward),
        _sortMenuItem(NoteSortMode.modifiedAsc, 'Modified: Oldest first'.tr(), Icons.arrow_upward),
      ],
    );
  }

  PopupMenuItem<NoteSortMode> _sortMenuItem(
    NoteSortMode mode,
    String label,
    IconData icon,
  ) {
    final isActive = _sortMode == mode;
    final cs = Theme.of(context).colorScheme;
    return PopupMenuItem<NoteSortMode>(
      value: mode,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isActive ? cs.primary : cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? cs.primary : null,
                fontWeight: isActive ? FontWeight.bold : null,
              ),
            ),
          ),
          if (isActive)
            Icon(Icons.check, size: 18, color: cs.primary),
        ],
      ),
    );
  }

  Widget _handleAndBuildNotes() {
    final String noNotes = 'No Notes'.tr();
    const double fontSize = 24.0;

    return Expanded(
      child: !isLoading
          ? notes.isEmpty
                ? Center(
                    child: Text(
                      noNotes,
                      style: const TextStyle(fontSize: fontSize),
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isGridView
                        ? _buildNotes(key: const ValueKey('grid'))
                        : _buildNotesTile(key: const ValueKey('list')),
                  )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _addANewNoteButton(BuildContext context) {
    return ExpandableFab(
      options: buildNoteCreationOptions(
        onText: () async {
          await Navigator.pushNamed(
            context,
            '/addnote',
            arguments: AddNoteArguments(
              sessionStream: widget.sessionStateStream,
              noteType: 'text',
            ),
          );
          refreshNotes();
        },
        onAudio: () async {
          await Navigator.pushNamed(
            context,
            '/addnote',
            arguments: AddNoteArguments(
              sessionStream: widget.sessionStateStream,
              noteType: 'audio',
            ),
          );
          refreshNotes();
        },
        onImage: () async {
          await Navigator.pushNamed(
            context,
            '/addnote',
            arguments: AddNoteArguments(
              sessionStream: widget.sessionStateStream,
              noteType: 'image',
            ),
          );
          refreshNotes();
        },
        onDrawing: () async {
          await Navigator.pushNamed(
            context,
            '/addnote',
            arguments: AddNoteArguments(
              sessionStream: widget.sessionStateStream,
              noteType: 'drawing',
            ),
          );
          refreshNotes();
        },
        onChecklist: () async {
          await Navigator.pushNamed(
            context,
            '/addnote',
            arguments: AddNoteArguments(
              sessionStream: widget.sessionStateStream,
              noteType: 'checklist',
            ),
          );
          refreshNotes();
        },
      ),
    );
  }

  Widget _buildSearch() {
    final String searchBoxHint = 'Search...'.tr();

    return SearchWidget(
      text: query,
      hintText: searchBoxHint,
      onChanged: _searchNote,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return HomeDrawer(
      onImportCallback: () async {
        Navigator.of(context).pop();
        widget.sessionStateStream.add(SessionState.stopListening);
        await showImportDialog(context, homeRefresh: refreshNotes);
        widget.sessionStateStream.add(SessionState.startListening);
      },
      onChangePassCallback: () async {
        var navigator = Navigator.of(context);
        await Navigator.pushNamed(context, '/changepassphrase');
        navigator.pop();
      },
      onLogoutCallback: () async {
        await Session.logout();
        widget.sessionStateStream.add(SessionState.stopListening);

        if (context.mounted) {
          await Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (Route<dynamic> route) => false,
            arguments: SessionArguments(
              sessionStream: widget.sessionStateStream,
              isKeyboardFocused: false,
            ),
          );
        }
      },
      onSettingsCallback: () async {
        var navigator = Navigator.of(context);
        await Navigator.pushNamed(
          context,
          '/settings',
          arguments: widget.sessionStateStream,
        );
        navigator.pop();
        refreshNotes();
      },
      onBiometricsCallback: () async {
        var navigator = Navigator.of(context);
        await Navigator.pushNamed(context, '/biometricSetting');
        navigator.pop();
      },
    );
  }

  Widget _buildNotesTile({Key? key}) {
    return ReorderableListView.builder(
      key: key,
      padding: const EdgeInsets.all(15),
      itemCount: notes.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        _onReorder(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final note = notes[index];
        final isSelected = _selectedNoteIds.contains(note.id);
        final tileWidget = PreferencesStorage.isCompactPreview
            ? NoteTileWidgetCompact(
                note: note,
                index: index,
                isSelected: isSelected,
                showDragHandle: _isSelectionMode,
              )
            : NoteTileWidget(
                note: note,
                index: index,
                isSelected: isSelected,
                showDragHandle: _isSelectionMode,
              );

        return Stack(
          key: ValueKey(note.id),
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _onNoteTap(note, index),
              onLongPress: () => _onNoteLongPress(note),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: tileWidget,
              ),
            ),
            if (_isSelectionMode)
              Positioned(
                top: 0,
                bottom: 7,
                right: 0,
                width: 48,
                child: ReorderableDragStartListener(
                  index: index,
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNotes({Key? key}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 180).floor().clamp(2, 6);
        return AlignedGridView.count(
          key: key,
          itemCount: notes.length,
          padding: const EdgeInsets.all(12),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          itemBuilder: (context, index) {
            final note = notes[index];
            final isSelected = _selectedNoteIds.contains(note.id);

            Widget cardWidget = PreferencesStorage.isCompactPreview
                ? NoteCardWidgetCompact(
                    note: note,
                    index: index,
                    isSelected: isSelected,
                    showDragHandle: _isSelectionMode,
                  )
                : NoteCardWidget(
                    note: note,
                    index: index,
                    isSelected: isSelected,
                    showDragHandle: _isSelectionMode,
                  );

            if (_isSelectionMode) {
              return DragTarget<int>(
                onAcceptWithDetails: (details) {
                  _onReorder(details.data, index);
                },
                builder: (context, candidateData, rejectedData) {
                  return LongPressDraggable<int>(
                    data: index,
                    feedback: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: (constraints.maxWidth - 24) / crossAxisCount - 4,
                        child: Opacity(
                          opacity: 0.85,
                          child: PreferencesStorage.isCompactPreview
                              ? NoteCardWidgetCompact(
                                  note: note, index: index, isSelected: false)
                              : NoteCardWidget(
                                  note: note, index: index, isSelected: false),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: cardWidget,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _onNoteTap(note, index),
                      child: cardWidget,
                    ),
                  );
                },
              );
            }

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _onNoteTap(note, index),
              onLongPress: () => _onNoteLongPress(note),
              child: cardWidget,
            );
          },
        );
      },
    );
  }

  void _searchNote(String query) {
    final notes = allnotes.where((note) {
      final titleLower = note.title.toLowerCase();
      final descriptionLower = note.description.toLowerCase();
      final queryLower = query.toLowerCase().trim();

      return titleLower.contains(queryLower) ||
          descriptionLower.contains(queryLower);
    }).toList();

    setState(() {
      this.query = query;
      this.notes = notes;
    });
  }

  void dismissKeyboard([dynamic _]) {
    final FocusScopeNode currentScope = FocusScope.of(context);
    if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
