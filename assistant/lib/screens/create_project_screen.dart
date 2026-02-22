// lib/screens/create_project_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final TextEditingController _goalController = TextEditingController();
  int _selectedDays = 7;
  bool _loading = false;
  List<String>? _createdTasks;

  final List<int> _dayOptions = [3, 5, 7, 10, 14, 21, 30];

  Future<void> _createProject() async {
    final goal = _goalController.text.trim();
    if (goal.isEmpty) {
      _showSnack('Hedefini yazmayı unutmuşsun! 😊');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ApiService.createProject(goal, _selectedDays);
      final tasks = List<String>.from(result['gorevler'] ?? []);
      setState(() => _createdTasks = tasks);
    } catch (e) {
      _showSnack('Bir hata oluştu, tekrar dene 😅');
    }
    setState(() => _loading = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF00E5A0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _createdTasks == null ? _buildForm() : _buildResult(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Başlık
        const Text('YENİ PROJE', style: TextStyle(color: Color(0xFF00E5A0), fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Hedefini Belirle', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Asistanın senin için plan oluşturacak 🤖', style: TextStyle(color: Colors.white38, fontSize: 14)),
        const SizedBox(height: 32),

        // Hedef input
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0F14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('🎯', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text('Hedefin ne?', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _goalController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Örn: Flutter uygulamamı bitirmek, Python öğrenmek...',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00E5A0), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Gün seçimi
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0F14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('📅', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text('Kaç günde tamamlayacaksın?', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _dayOptions.map((day) {
                  final selected = _selectedDays == day;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDays = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF00E5A0) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? const Color(0xFF00E5A0) : Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Text(
                        '$day gün',
                        style: TextStyle(
                          color: selected ? Colors.black : Colors.white54,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Seçili gün göstergesi
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5A0).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00E5A0).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF00E5A0), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Asistan $_selectedDays günlük görev planı oluşturacak',
                        style: const TextStyle(color: Color(0xFF00E5A0), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Oluştur butonu
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _createProject,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5A0),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('Planı Oluştur 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),

        const SizedBox(height: 16),

        // Mevcut projeye dön
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Geri Dön', style: TextStyle(color: Colors.white38, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('✅ HAZIR!', style: TextStyle(color: Color(0xFF00E5A0), fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Planın Oluşturuldu', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('$_selectedDays günlük yol haritana hazır! 🎉', style: const TextStyle(color: Colors.white38, fontSize: 14)),
        const SizedBox(height: 24),

        // Asistan mesajı
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF00E5A0).withOpacity(0.08), const Color(0xFF4FC3F7).withOpacity(0.04)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00E5A0).withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('🤖', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text('Asistan Diyor ki...', style: TextStyle(color: Color(0xFF00E5A0), fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '"${_goalController.text}" hedefin için $_selectedDays günlük planı hazırladım! Her gün küçük adımlar büyük başarılar getirir. Hadi başlayalım! 💪',
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Görev listesi
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0F14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Görevlerin', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ...(_createdTasks ?? []).asMap().entries.map((entry) {
                final i = entry.key;
                final task = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5A0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00E5A0).withOpacity(0.3)),
                        ),
                        child: Center(
                          child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF00E5A0), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(task, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Başla butonu
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5A0),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Harika, Başlayalım! 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}