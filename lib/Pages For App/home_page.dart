import 'package:flutter/material.dart';
import 'editor_page.dart';
import 'gallery_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50, // ✅ background lembut
      appBar: AppBar(
        title: const Text("Image Editor Home"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // ✅ jarak sekeliling
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMenuButton(
                context,
                icon: Icons.edit,
                text: "Editor For Pictures",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditorPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildMenuButton(
                context,
                icon: Icons.photo_library,
                text: "Gallery of Edited Pictures",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GalleryPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Widget tombol biar konsisten
  Widget _buildMenuButton(BuildContext context,
      {required IconData icon,
        required String text,
        required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 26, color: Colors.white), // ✅ Ikon putih
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white, // ✅ Teks putih
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple, // ✅ warna tombol
          foregroundColor: Colors.white, // ✅ pastikan teks/ikon putih
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4, // ✅ ada shadow
        ),
        onPressed: onTap,
      ),
    );
  }
}
