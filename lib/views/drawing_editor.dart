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
import 'dart:io';
import 'dart:ui' as ui;

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:easy_localization/easy_localization.dart';
import 'package:local_session_timeout/local_session_timeout.dart';
import 'package:path_provider/path_provider.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

// Project imports:
import 'package:safenotes/data/database_handler.dart';
import 'package:safenotes/data/preference_and_config.dart';
import 'package:safenotes/encryption/aes_encryption.dart';
import 'package:safenotes/models/attachment.dart';
import 'package:safenotes/models/safenote.dart';
import 'package:uuid/uuid.dart';

enum DrawingTool { pen, brush, eraser, line, rectangle, circle }

class DrawingEditor extends StatefulWidget {
  final StreamController<SessionState> sessionStateStream;
  final SafeNote? note;

  const DrawingEditor({
    super.key,
    required this.sessionStateStream,
    this.note,
  });

  @override
  State<DrawingEditor> createState() => _DrawingEditorState();
}

class _DrawingEditorState extends State<DrawingEditor> {
  final _titleController = TextEditingController();
  final _canvasKey = GlobalKey();

  final List<_DrawStroke> _strokes = [];
  final List<_DrawStroke> _redoStack = [];
  _DrawStroke? _currentStroke;

  DrawingTool _tool = DrawingTool.pen;
  Color _color = Colors.black;
  double _strokeWidth = 4.0;

  Offset? _shapeStart;

  final List<Color> _palette = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    final pos = details.localPosition;
    setState(() {
      _redoStack.clear();
      if (_tool == DrawingTool.line ||
          _tool == DrawingTool.rectangle ||
          _tool == DrawingTool.circle) {
        _shapeStart = pos;
        _currentStroke = _DrawStroke(
          points: [pos],
          color: _color,
          width: _strokeWidth,
          tool: _tool,
          isEraser: false,
        );
      } else {
        _currentStroke = _DrawStroke(
          points: [pos],
          color: _tool == DrawingTool.eraser ? Colors.white : _color,
          width: _tool == DrawingTool.eraser
              ? _strokeWidth * 4
              : _strokeWidth,
          tool: _tool,
          isEraser: _tool == DrawingTool.eraser,
        );
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final pos = details.localPosition;
    setState(() {
      if (_currentStroke == null) return;
      if (_tool == DrawingTool.line ||
          _tool == DrawingTool.rectangle ||
          _tool == DrawingTool.circle) {
        _currentStroke = _currentStroke!.copyWith(
          points: [_shapeStart!, pos],
        );
      } else {
        _currentStroke = _currentStroke!.copyWith(
          points: [..._currentStroke!.points, pos],
        );
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke != null) {
      setState(() {
        _strokes.add(_currentStroke!);
        _currentStroke = null;
        _shapeStart = null;
      });
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _redoStack.add(_strokes.removeLast());
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        _strokes.add(_redoStack.removeLast());
      });
    }
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final title = _titleController.text.isEmpty
        ? 'Drawing'.tr()
        : _titleController.text;

    final boundary = _canvasKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final pngBytes = byteData.buffer.asUint8List();

    final note = SafeNote(
      title: title,
      description: 'drawing_note',
      createdTime: DateTime.now(),
      noteType: 'drawing',
      contentFormat: 'plain',
    );

    final saved = await NotesDatabase.instance.encryptAndStore(note);

    if (saved.id != null) {
      final dir = await getApplicationDocumentsDirectory();
      final attachDir = Directory('${dir.path}/attachments/${saved.id}');
      if (!await attachDir.exists()) {
        await attachDir.create(recursive: true);
      }

      final encrypted = encryptAES(
        String.fromCharCodes(pngBytes),
        PhraseHandler.getPass,
      );
      final encPath = '${attachDir.path}/${const Uuid().v4()}.enc';
      await File(encPath).writeAsString(encrypted);

      await NotesDatabase.instance.insertAttachment(NoteAttachment(
        noteId: saved.id!,
        fileName: 'drawing.png',
        storagePath: encPath,
        mimeType: 'image/png',
        fileSize: pngBytes.length,
        createdTime: DateTime.now(),
      ));
    }

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Drawing'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _strokes.isNotEmpty ? _undo : null,
            tooltip: 'Undo'.tr(),
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redoStack.isNotEmpty ? _redo : null,
            tooltip: 'Redo'.tr(),
          ),
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
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              controller: _titleController,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Title'.tr(),
              ),
            ),
          ),
          _buildToolbar(cs),
          _buildColorPalette(cs),
          Expanded(
            child: RepaintBoundary(
              key: _canvasKey,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Container(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  child: CustomPaint(
                    painter: _DrawingPainter(
                      strokes: _strokes,
                      currentStroke: _currentStroke,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(ColorScheme cs) {
    Widget toolBtn(DrawingTool tool, IconData icon, String label) {
      final selected = _tool == tool;
      return Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _tool = tool),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected ? cs.primaryContainer : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
              color: selected ? cs.onPrimaryContainer : cs.onSurface,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          toolBtn(DrawingTool.pen, Icons.edit, 'Pen'.tr()),
          toolBtn(DrawingTool.brush, Icons.brush, 'Brush'.tr()),
          toolBtn(DrawingTool.eraser, Icons.auto_fix_normal, 'Eraser'.tr()),
          const SizedBox(width: 8),
          toolBtn(DrawingTool.line, Icons.horizontal_rule, 'Line'.tr()),
          toolBtn(DrawingTool.rectangle, Icons.crop_square, 'Rectangle'.tr()),
          toolBtn(DrawingTool.circle, Icons.circle_outlined, 'Circle'.tr()),
          const Spacer(),
          SizedBox(
            width: 120,
            child: Slider(
              value: _strokeWidth,
              min: 1,
              max: 20,
              onChanged: (v) => setState(() => _strokeWidth = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: _palette.map((c) {
          final selected = _color == c;
          return GestureDetector(
            onTap: () => setState(() => _color = c),
            child: Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? cs.primary : cs.outline,
                  width: selected ? 3 : 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DrawStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final DrawingTool tool;
  final bool isEraser;

  const _DrawStroke({
    required this.points,
    required this.color,
    required this.width,
    required this.tool,
    this.isEraser = false,
  });

  _DrawStroke copyWith({List<Offset>? points}) => _DrawStroke(
    points: points ?? this.points,
    color: color,
    width: width,
    tool: tool,
    isEraser: isEraser,
  );
}

class _DrawingPainter extends CustomPainter {
  final List<_DrawStroke> strokes;
  final _DrawStroke? currentStroke;

  _DrawingPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in [...strokes, if (currentStroke != null) currentStroke!]) {
      _paintStroke(canvas, stroke);
    }
  }

  void _paintStroke(Canvas canvas, _DrawStroke stroke) {
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;

    if (stroke.tool == DrawingTool.line && stroke.points.length == 2) {
      canvas.drawLine(stroke.points.first, stroke.points.last, paint);
      return;
    }

    if (stroke.tool == DrawingTool.rectangle && stroke.points.length == 2) {
      canvas.drawRect(
        Rect.fromPoints(stroke.points.first, stroke.points.last),
        paint,
      );
      return;
    }

    if (stroke.tool == DrawingTool.circle && stroke.points.length == 2) {
      canvas.drawOval(
        Rect.fromPoints(stroke.points.first, stroke.points.last),
        paint,
      );
      return;
    }

    if (stroke.tool == DrawingTool.pen || stroke.tool == DrawingTool.eraser) {
      final inputPoints = stroke.points
          .map((p) => PointVector(p.dx, p.dy))
          .toList();
      final outlinePoints = getStroke(
        inputPoints,
        options: StrokeOptions(
          size: stroke.width,
          thinning: stroke.tool == DrawingTool.eraser ? 0 : 0.5,
          smoothing: 0.5,
          streamline: 0.5,
        ),
      );

      if (outlinePoints.length < 2) return;
      final path = Path();
      path.moveTo(outlinePoints.first.dx, outlinePoints.first.dy);
      for (var i = 1; i < outlinePoints.length - 1; i++) {
        final p0 = outlinePoints[i];
        final p1 = outlinePoints[i + 1];
        path.quadraticBezierTo(
          p0.dx, p0.dy,
          (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2,
        );
      }
      canvas.drawPath(
        path,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    // Brush: simple path
    if (stroke.points.length < 2) return;
    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (var i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter old) => true;
}
