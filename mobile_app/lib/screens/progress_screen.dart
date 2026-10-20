import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_app/services/auth_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  List<dynamic> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  Future<void> _fetchPhotos() async {
    final uid = AuthService.instance.loggedInUser?.cedula ?? '';
    if (uid.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final url = Uri.parse('${AuthService.apiBaseUrl}/api/progress/$uid');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() {
          _photos = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final uid = AuthService.instance.loggedInUser?.cedula ?? '';
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AuthService.apiBaseUrl}/api/progress/upload'),
      );
      request.fields['user_id'] = uid;
      
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: image.name));
      
      var response = await request.send();
      if (response.statusCode == 200) {
        await _fetchPhotos();
      }
    } catch (_) {
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        title: const Text('Mi Progreso (IA Vision)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F192B),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF8BE0C0)))
        : _photos.isEmpty 
          ? const Center(child: Text('No hay fotos de progreso aún.', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _photos.length,
              itemBuilder: (ctx, i) {
                final item = _photos[i];
                return Card(
                  color: const Color(0xFF101B2D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item['photo_url'] != null)
                           ClipRRect(
                             borderRadius: BorderRadius.circular(12),
                             child: Image.network(item['photo_url'], height: 300, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___) => const SizedBox()),
                           ),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Color(0xFF8BE0C0), size: 20),
                            SizedBox(width: 8),
                            Text('Análisis Gemini Vision', style: TextStyle(color: Color(0xFF8BE0C0), fontWeight: FontWeight.bold)),
                          ]
                        ),
                        const SizedBox(height: 8),
                        Text(item['ai_analysis'] ?? 'Sin análisis', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8BE0C0),
        foregroundColor: const Color(0xFF0B1220),
        onPressed: _isUploading ? null : _uploadPhoto,
        icon: _isUploading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF0B1220), strokeWidth: 2)) : const Icon(Icons.add_a_photo),
        label: Text(_isUploading ? 'Analizando...' : 'Subir Foto'),
      ),
    );
  }
}
