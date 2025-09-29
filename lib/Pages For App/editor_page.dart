import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_editor_app/Models/drawn_line.dart';
import 'package:gallery_editor_app/Models/drawing_mode.dart';
import 'package:gallery_editor_app/Models/text_element.dart';
import 'package:gallery_editor_app/Painters/sketcher.dart';
import 'gallery_page.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final List<DrawnLine> _lines = [];
  final List<TextElement> _texts = [];
  DrawingMode _currentMode = DrawingMode.pen;

  Color _selectedColor = Colors.black;
  double _brushSize = 4.0;
  double _textSize = 20.0;

  Uint8List? _backgroundImage;
  final GlobalKey _canvasKey = GlobalKey();

  // --- Preview states ---
  Offset? _currentOffset;
  DrawnLine? _currentLine;

  // ambil gambar dari komputer (PNG/JPG/JPEG)
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );
    if (result != null) {
      if (result.files.single.bytes != null) {
        setState(() => _backgroundImage = result.files.single.bytes);
      } else if (result.files.single.path != null) {
        setState(() => _backgroundImage = File(result.files.single.path!).readAsBytesSync());
      }
    }
  }

  // simpan hasil edit ke file PNG → lalu buka GalleryPage
  Future<void> _saveToGallery() async {
    try {
      final boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final pngBytes = byteData.buffer.asUint8List();
        final dir = await getApplicationDocumentsDirectory();
        final file = File("${dir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png");
        await file.writeAsBytes(pngBytes);

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GalleryPage()),
        );
      }
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  // tambah text baru
  void _addText() {
    setState(() {
      _texts.add(TextElement(
        id: DateTime.now().toIso8601String(),
        text: "Edit me",
        position: const Offset(100, 100),
        style: TextStyle(color: _selectedColor, fontSize: _textSize),
      ));
    });
  }

  // pilih warna
  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pick a color"),
          content: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        );
      },
    );
  }

  // handle drawing
  void _startDrawing(Offset pos) {
    if (_currentMode == DrawingMode.eraser) {
      setState(() {
        _lines.removeWhere((line) {
          return line.path.any((p) => (p - pos).distance < line.width * 2);
        });
      });
    } else if (_currentMode == DrawingMode.pen || _currentMode == DrawingMode.highlight) {
      setState(() {
        _currentLine = DrawnLine(
          path: [pos],
          color: _currentMode == DrawingMode.highlight
              ? _selectedColor.withOpacity(0.3)
              : _selectedColor,
          width: _brushSize,
          mode: _currentMode,
        );
        _lines.add(_currentLine!);
      });
    }
  }

  void _updateDrawing(Offset pos) {
    setState(() {
      _currentOffset = pos;
      if (_currentLine != null &&
          (_currentMode == DrawingMode.pen || _currentMode == DrawingMode.highlight)) {
        _currentLine!.path.add(pos);
      }
    });
  }

  void _endDrawing() {
    setState(() {
      _currentLine = null;
      _currentOffset = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Editor"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveToGallery),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _canvasKey,
              child: GestureDetector(
                onPanStart: (details) => _startDrawing(details.localPosition),
                onPanUpdate: (details) => _updateDrawing(details.localPosition),
                onPanEnd: (_) => _endDrawing(),
                child: Container(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      if (_backgroundImage != null)
                        Positioned.fill(
                          child: Image.memory(_backgroundImage!, fit: BoxFit.contain),
                        ),
                      CustomPaint(
                        painter: Sketcher(lines: _lines, texts: _texts),
                        size: Size.infinite,
                      ),
                      // text draggable
                      ..._texts.map((txt) {
                        return Positioned(
                          left: txt.position.dx,
                          top: txt.position.dy,
                          child: Draggable(
                            feedback: Material(
                              color: Colors.transparent,
                              child: Text(txt.text, style: txt.style),
                            ),
                            childWhenDragging: Container(),
                            onDragEnd: (details) {
                              setState(() {
                                txt.position = details.offset;
                              });
                            },
                            child: GestureDetector(
                              onTap: () async {
                                final newText = await _editTextDialog(txt.text);
                                if (newText != null) {
                                  setState(() {
                                    txt.text = newText;
                                  });
                                }
                              },
                              child: Text(txt.text, style: txt.style),
                            ),
                          ),
                        );
                      }),
                      // --- Brush / Eraser preview ---
                      if (_currentOffset != null)
                        Positioned(
                          left: _currentOffset!.dx - _brushSize / 2,
                          top: _currentOffset!.dy - _brushSize / 2,
                          child: IgnorePointer(
                            child: Container(
                              width: _brushSize,
                              height: _brushSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _currentMode == DrawingMode.eraser
                                      ? Colors.grey.withOpacity(0.7)
                                      : _selectedColor.withOpacity(0.8),
                                  width: 1.5,
                                ),
                                color: _currentMode == DrawingMode.eraser
                                    ? Colors.grey.withOpacity(0.3)
                                    : _selectedColor.withOpacity(0.2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_currentMode == DrawingMode.pen || _currentMode == DrawingMode.highlight)
            Column(
              children: [
                const Text("Brush Size"),
                Slider(
                  value: _brushSize,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: "${_brushSize.round()} px",
                  onChanged: (val) {
                    setState(() => _brushSize = val);
                  },
                ),
              ],
            ),
          if (_currentMode == DrawingMode.text)
            Column(
              children: [
                const Text("Text Size"),
                Slider(
                  value: _textSize,
                  min: 8,
                  max: 100,
                  divisions: 92,
                  label: "${_textSize.round()} px",
                  onChanged: (val) {
                    setState(() {
                      _textSize = val;
                      for (var t in _texts) {
                        t.style = t.style.copyWith(fontSize: _textSize);
                      }
                    });
                  },
                ),
              ],
            ),
          Container(
            color: Colors.deepPurple.shade100,
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(icon: const Icon(Icons.color_lens), onPressed: _pickColor),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _currentMode = DrawingMode.pen),
                ),
                IconButton(
                  icon: const Icon(Icons.brush),
                  onPressed: () => setState(() => _currentMode = DrawingMode.highlight),
                ),
                IconButton(
                  icon: const Icon(Icons.text_fields),
                  onPressed: () {
                    setState(() => _currentMode = DrawingMode.text);
                    _addText();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.format_color_reset),
                  onPressed: () => setState(() => _currentMode = DrawingMode.eraser),
                ),
                IconButton(icon: const Icon(Icons.image), onPressed: _pickImage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _editTextDialog(String currentText) {
    final controller = TextEditingController(text: currentText);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Text"),
          content: TextField(controller: controller),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("Save")),
          ],
        );
      },
    );
  }
}
