// lib/screens/daily_analysis_screen.dart

import 'package:flutter/material.dart';
import '../models/analysis.dart';
import '../services/api_service.dart';

class DailyAnalysisScreen extends StatefulWidget {
  const DailyAnalysisScreen({super.key});

  @override
  State<DailyAnalysisScreen> createState() => _DailyAnalysisScreenState();
}

class _DailyAnalysisScreenState extends State<DailyAnalysisScreen> {
  late Future<Analysis> _analysisFuture;
  Map<String, dynamic>? _tasksData;
  final TextEditingController _noteController = TextEditingController();
  bool _sendingNote = false;
  String? _completionMsg;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _analysisFuture = ApiService.fetchAnalysis();
    });
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final data = await ApiService.getTasks();
      setState(() => _tasksData = data);
    } catch (_) {}
  }

  Future<void> _completeTask(int index) async {
    try {
      final result = await ApiService.completeTask(index);
      setState(() => _completionMsg = result['yorum'] ?? '');
      _reload();
      if (_completionMsg != null && _completionMsg!.isNotEmpty) {
        _showAIDialog(_completionMsg!);
      }
    } catch (e) {
      _showSnack('Hata olustu');
    }
  }

  void _showAIDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D0F14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🤖', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Asistan', style: TextStyle(color: Color(0xFF00E5A0), fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5A0),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Tesekkurler!', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingNote = true);
    try {
      final result = await ApiService.addProgress(text);
      _noteController.clear();
      _showSnack(result['yorum'] ?? 'Not kaydedildi!');
      _reload();
    } catch (e) {
      _showSnack('Bir hata olustu');
    }
    setState(() => _sendingNote = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF00E5A0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      body: SafeArea(
        child: FutureBuilder<Analysis>(
          future: _analysisFuture,
          builder: (context, snapshot) {
            return CustomScrollView(
              slivers: [
                _buildHeader(),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverToBoxAdapter(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF00E5A0))),
                  ))
                else if (snapshot.hasData)
                  SliverList(
                    delegate: SliverChildListDelegate([
                      _buildAnalysisCard(snapshot.data!),
                      _buildSekreterKart(snapshot.data!.tavsiye),
                      _buildTaskList(),
                      _buildNoteInput(),
                      const SizedBox(height: 80),
                    ]),
                  )
                else
                  SliverFillRemaining(child: _buildError()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final gunler = ['Pazartesi','Sali','Carsamba','Persembe','Cuma','Cumartesi','Pazar'];
    final aylar = ['Ocak','Subat','Mart','Nisan','Mayis','Haziran','Temmuz','Agustos','Eylul','Ekim','Kasim','Aralik'];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${gunler[now.weekday - 1]}, ${now.day} ${aylar[now.month - 1]}',
              style: const TextStyle(color: Color(0xFF00E5A0), fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gunluk Analiz', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.pushNamed(context, '/create');
                    if (result == true) _reload();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5A0).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00E5A0).withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add_rounded, color: Color(0xFF00E5A0), size: 16),
                        SizedBox(width: 4),
                        Text('Yeni Proje', style: TextStyle(color: Color(0xFF00E5A0), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Asistanin seni takip ediyor 🤖', style: TextStyle(color: Colors.white38, fontSize: 14)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(Analysis a) {
    final oran = int.tryParse(a.basariOrani.replaceAll('%', '')) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HEDEF', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 2)),
                      const SizedBox(height: 4),
                      Text(a.hedef, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                _CircleProgress(value: oran / 100),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _StatChip(label: 'Tamamlanan', value: '${a.tamamlananGorev}', icon: Icons.check_circle_rounded, color: const Color(0xFF00E5A0)),
                const SizedBox(width: 10),
                _StatChip(label: 'Notlar', value: '${a.notSayisi}', icon: Icons.notes_rounded, color: const Color(0xFF4FC3F7)),
                const SizedBox(width: 10),
                _StatChip(label: 'Basari', value: a.basariOrani, icon: Icons.trending_up_rounded, color: const Color(0xFFCE93D8)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _durumRenk(a.durum).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(a.durum, style: TextStyle(color: _durumRenk(a.durum), fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Color _durumRenk(String durum) {
    if (durum.contains('Tamamlandi')) return const Color(0xFF00E5A0);
    if (durum.contains('yakin')) return const Color(0xFF4FC3F7);
    if (durum.contains('var')) return const Color(0xFFFFD54F);
    return const Color(0xFFFF7043);
  }

  Widget _buildSekreterKart(String tavsiye) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
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
                Text('Asistan Diyor ki...', style: TextStyle(color: Color(0xFF00E5A0), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 12),
            Text(tavsiye, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    if (_tasksData == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF00E5A0), strokeWidth: 2)),
      );
    }

    final tasks = List<String>.from(_tasksData!['tasks'] ?? []);
    final completed = List<String>.from(_tasksData!['completed'] ?? []);

    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0F14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          padding: const EdgeInsets.all(24),
          child: const Center(
            child: Column(
              children: [
                Text('📋', style: TextStyle(fontSize: 32)),
                SizedBox(height: 8),
                Text('Henuz gorev yok', style: TextStyle(color: Colors.white38, fontSize: 14)),
                SizedBox(height: 4),
                Text('Sag ustten "Yeni Proje" olustur', style: TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    final bekleyen = tasks.where((t) => !completed.contains(t)).toList();
    final biten = tasks.where((t) => completed.contains(t)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('📋', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text('Gorev Listesi', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5A0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${completed.length}/${tasks.length}',
                    style: const TextStyle(color: Color(0xFF00E5A0), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bekleyen görevler
            if (bekleyen.isNotEmpty) ...[
              const Text('BEKLEYENLER', style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 8),
              ...bekleyen.map((task) {
                final index = tasks.indexOf(task);
                return _TaskItem(
                  task: task,
                  isDone: false,
                  onTap: () => _completeTask(index),
                );
              }),
              const SizedBox(height: 12),
            ],

            // Tamamlanan görevler
            if (biten.isNotEmpty) ...[
              const Text('TAMAMLANANLAR', style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 8),
              ...biten.map((task) => _TaskItem(task: task, isDone: true, onTap: null)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoteInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
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
                Text('✍️', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text('Gunluk Not', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Bugun ne yaptin? Nasil gecti?',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF00E5A0), width: 1.5)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sendingNote ? null : _sendNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5A0),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _sendingNote
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('Backend\'e baglanılamadi', style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _reload,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5A0), foregroundColor: Colors.black),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String task;
  final bool isDone;
  final VoidCallback? onTap;
  const _TaskItem({required this.task, required this.isDone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFF00E5A0).withOpacity(0.06) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDone ? const Color(0xFF00E5A0).withOpacity(0.2) : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFF00E5A0) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDone ? const Color(0xFF00E5A0) : Colors.white30,
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Colors.black, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task,
                style: TextStyle(
                  color: isDone ? Colors.white38 : Colors.white,
                  fontSize: 14,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.white38,
                ),
              ),
            ),
            if (!isDone)
              const Icon(Icons.touch_app_rounded, color: Colors.white12, size: 16),
          ],
        ),
      ),
    );
  }
}

class _CircleProgress extends StatelessWidget {
  final double value;
  const _CircleProgress({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60, height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            backgroundColor: Colors.white.withOpacity(0.06),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5A0)),
            strokeWidth: 5,
          ),
          Text('${(value * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}