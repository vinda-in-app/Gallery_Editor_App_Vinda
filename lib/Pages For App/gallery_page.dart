import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<File> _images = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = Directory(dir.path)
        .listSync()
        .where((f) => f.path.endsWith(".png"))
        .map((f) => File(f.path))
        .toList();

    setState(() {
      _images = files.reversed.toList(); // urutan terbaru di atas
    });
  }

  Future<void> _deleteImage(File file) async {
    if (await file.exists()) {
      await file.delete();
      _loadImages();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image deleted")),
      );
    }
  }

  void _openImage(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Image.file(file, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gallery")),
      body: _images.isEmpty
          ? const Center(child: Text("No saved images yet"))
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 kolom
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _images.length,
        itemBuilder: (_, i) {
          final file = _images[i];
          return GestureDetector(
            onTap: () => _openImage(file),
            onLongPress: () => _deleteImage(file),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.file(file, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}
