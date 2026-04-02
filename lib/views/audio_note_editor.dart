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
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:local_session_timeout/local_session_timeout.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

// Project imports:
import 'package:safenotes/data/database_handler.dart';
import 'package:safenotes/data/preference_and_config.dart';
import 'package:safenotes/encryption/aes_encryption.dart';
import 'package:safenotes/models/attachment.dart';
import 'package:safenotes/models/safenote.dart';
import 'package:uuid/uuid.dart';

class AudioNoteEditor extends StatefulWidget {
  final StreamController<SessionState> sessionStateStream;
  final SafeNote? note;

  const AudioNoteEditor({
    super.key,
    required this.sessionStateStream,
    this.note,
  });

  @override
  State<AudioNoteEditor> createState() => _AudioNoteEditorState();
}

class _AudioNoteEditorState extends State<AudioNoteEditor> {
  final _titleController = TextEditingController();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  Duration _recordDuration = Duration.zero;
  Duration _playPosition = Duration.zero;
  Duration _playDuration = Duration.zero;
  Timer? _durationTimer;
  List<double> _waveformData = [];

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _hasRecording = true;
    }
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _playPosition = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _playDuration = dur);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      _recordingPath = '${dir.path}/audio_${const Uuid().v4()}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _recordingPath!,
      );
      _waveformData = [];
      _recordDuration = Duration.zero;
      _durationTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) async {
          if (!mounted) return;
          final amp = await _recorder.getAmplitude();
          setState(() {
            _recordDuration += const Duration(milliseconds: 100);
            final normalized = (amp.current + 50).clamp(0, 50) / 50.0;
            _waveformData.add(normalized);
          });
        },
      );
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopRecording() async {
    _durationTimer?.cancel();
    await _recorder.stop();
    setState(() {
      _isRecording = false;
      _hasRecording = true;
    });
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else if (_recordingPath != null) {
      await _player.play(DeviceFileSource(_recordingPath!));
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _save() async {
    if (!_hasRecording || _recordingPath == null) return;

    final navigator = Navigator.of(context);
    final title = _titleController.text.isEmpty
        ? 'Audio Note'.tr()
        : _titleController.text;

    final note = SafeNote(
      title: title,
      description: 'audio_note',
      createdTime: DateTime.now(),
      noteType: 'audio',
      contentFormat: 'plain',
    );

    final saved = await NotesDatabase.instance.encryptAndStore(note);

    if (saved.id != null) {
      final dir = await getApplicationDocumentsDirectory();
      final attachDir = Directory('${dir.path}/attachments/${saved.id}');
      if (!await attachDir.exists()) {
        await attachDir.create(recursive: true);
      }

      final sourceBytes = await File(_recordingPath!).readAsBytes();
      final encrypted = encryptAES(
        String.fromCharCodes(sourceBytes),
        PhraseHandler.getPass,
      );
      final encPath = '${attachDir.path}/${const Uuid().v4()}.enc';
      await File(encPath).writeAsString(encrypted);

      await NotesDatabase.instance.insertAttachment(NoteAttachment(
        noteId: saved.id!,
        fileName: 'recording.m4a',
        storagePath: encPath,
        mimeType: 'audio/m4a',
        fileSize: sourceBytes.length,
        createdTime: DateTime.now(),
      ));
    }

    navigator.pop();
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Note'.tr()),
        actions: [
          if (_hasRecording)
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextFormField(
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
            const Divider(),
            const Spacer(),
            if (_waveformData.isNotEmpty) _buildWaveform(cs),
            const SizedBox(height: 20),
            Text(
              _isRecording
                  ? _formatDuration(_recordDuration)
                  : _hasRecording
                      ? '${_formatDuration(_playPosition)} / ${_formatDuration(_playDuration)}'
                      : '00:00',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_hasRecording && !_isRecording)
                  IconButton.filled(
                    onPressed: _togglePlayback,
                    iconSize: 36,
                    style: IconButton.styleFrom(
                      backgroundColor: cs.secondaryContainer,
                      foregroundColor: cs.onSecondaryContainer,
                    ),
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                  ),
                const SizedBox(width: 24),
                FloatingActionButton.large(
                  heroTag: 'recordBtn',
                  onPressed:
                      _isRecording ? _stopRecording : _startRecording,
                  backgroundColor:
                      _isRecording ? cs.error : cs.primaryContainer,
                  foregroundColor:
                      _isRecording ? cs.onError : cs.onPrimaryContainer,
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 36,
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform(ColorScheme cs) {
    return SizedBox(
      height: 80,
      child: CustomPaint(
        size: const Size(double.infinity, 80),
        painter: _WaveformPainter(
          data: _waveformData,
          color: cs.primary,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _WaveformPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final maxBars = (size.width / 4).floor();
    final startIdx = max(0, data.length - maxBars);
    final visibleData = data.sublist(startIdx);
    final barWidth = size.width / maxBars;

    for (var i = 0; i < visibleData.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final barHeight = visibleData[i] * size.height * 0.8;
      final y1 = (size.height - barHeight) / 2;
      final y2 = y1 + barHeight;
      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      data.length != old.data.length;
}
