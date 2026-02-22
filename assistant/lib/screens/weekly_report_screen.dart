// lib/screens/weekly_report_screen.dart

import 'package:flutter/material.dart';
import '../models/analysis.dart';
import '../services/api_service.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  late Future<WeeklyReport> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchWeeklyReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      body: SafeArea(
        child: FutureBuilder<WeeklyReport>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5A0)));
            }
            if (snap.hasError || !snap.hasData) {
              return Center(child: Text('Hata: ${snap.error}', style: const TextStyle(color: Colors.white54)));
            }
            final r = snap.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Text('HAFTALIK RAPOR', style: TextStyle(color: Color(0xFF00E5A0), fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Bu Haftanın Özeti', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Özet kartları
                  Row(
                    children: [
                      _SummaryCard(label: 'Ort. Başarı', value: '%${r.ortalamaBasari.toInt()}', color: const Color(0xFF00E5A0)),
                      const SizedBox(width: 12),
                      _SummaryCard(label: 'Aktif Gün', value: '${r.aktifGunSayisi}', color: const Color(0xFF4FC3F7)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Bar chart
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
                        const Text('Günlük Dağılım', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        _WeekBarChart(days: r.haftaOzeti),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gün detayları
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
                        const Text('Günlük Detay', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ...r.haftaOzeti.map((d) => _DayRow(day: d)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sekreter yorumu
                  _SekreterKart(yorum: r.sekreterYorumu, emoji: '📊'),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WeekBarChart extends StatelessWidget {
  final List<DayData> days;
  const _WeekBarChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final maxVal = days.fold<int>(1, (prev, d) => d.basariOrani > prev ? d.basariOrani : prev);
    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final isToday = d.tarih == DateTime.now().toIso8601String().split('T')[0];
          final barH = maxVal > 0 ? (d.basariOrani / 100) * 80 + 4 : 4.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${d.basariOrani}%', style: TextStyle(color: isToday ? const Color(0xFF00E5A0) : Colors.white38, fontSize: 9)),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    height: barH,
                    decoration: BoxDecoration(
                      color: isToday ? const Color(0xFF00E5A0) : const Color(0xFF4FC3F7).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(d.gun.substring(0, 3), style: TextStyle(color: isToday ? const Color(0xFF00E5A0) : Colors.white38, fontSize: 10, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final DayData day;
  const _DayRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final isActive = day.tamamlanan > 0 || day.notSayisi > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(day.gun, style: TextStyle(color: isActive ? Colors.white : Colors.white38, fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: day.basariOrani / 100,
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(
                  day.basariOrani >= 80 ? const Color(0xFF00E5A0) :
                  day.basariOrani >= 50 ? const Color(0xFF4FC3F7) :
                  day.basariOrani > 0 ? const Color(0xFFFFD54F) : Colors.white12,
                ),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text('%${day.basariOrani}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _SekreterKart extends StatelessWidget {
  final String yorum;
  final String emoji;
  const _SekreterKart({required this.yorum, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text('Asistan Değerlendirmesi', style: TextStyle(color: Color(0xFF00E5A0), fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(yorum, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }
}