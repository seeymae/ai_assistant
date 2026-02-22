// lib/screens/monthly_report_screen.dart

import 'package:flutter/material.dart';
import '../models/analysis.dart';
import '../services/api_service.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  late Future<MonthlyReport> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchMonthlyReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      body: SafeArea(
        child: FutureBuilder<MonthlyReport>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5A0)));
            }
            if (snap.hasError || !snap.hasData) {
              return Center(child: Text('Hata oluştu', style: const TextStyle(color: Colors.white54)));
            }
            final r = snap.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Text('AYLIK RAPOR', style: TextStyle(color: Color(0xFFCE93D8), fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(r.ay, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Ana başarı göstergesi
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0F14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: CircularProgressIndicator(
                                value: r.ortalamaBasari / 100,
                                backgroundColor: Colors.white.withOpacity(0.06),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  r.ortalamaBasari >= 75 ? const Color(0xFF00E5A0) :
                                  r.ortalamaBasari >= 50 ? const Color(0xFF4FC3F7) :
                                  const Color(0xFFFFD54F),
                                ),
                                strokeWidth: 10,
                              ),
                            ),
                            Column(
                              children: [
                                Text('%${r.ortalamaBasari.toInt()}',
                                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                                const Text('başarı', style: TextStyle(color: Colors.white38, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MonthStat(label: 'Aktif Gün', value: '${r.aktifGun}', color: const Color(0xFF4FC3F7)),
                            _MonthStat(label: 'Görev', value: '${r.toplamTamamlanan}', color: const Color(0xFF00E5A0)),
                            _MonthStat(label: 'Not', value: '${r.toplamNot}', color: const Color(0xFFCE93D8)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ay sonu bildirimi
                  if (r.aySonuBildirimi && r.bildirimMesaji != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCE93D8).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFCE93D8).withOpacity(0.3)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text('🎊', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(r.bildirimMesaji!, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                          ),
                        ],
                      ),
                    ),

                  // Performans değerlendirmesi
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0F14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Performans Değerlendirmesi', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        _PerformanceBar(label: 'Başarı Oranı', value: r.ortalamaBasari / 100, color: const Color(0xFF00E5A0)),
                        const SizedBox(height: 10),
                        _PerformanceBar(
                          label: 'Aktiflik',
                          value: r.aktifGun / 30,
                          color: const Color(0xFF4FC3F7),
                        ),
                        const SizedBox(height: 10),
                        _PerformanceBar(
                          label: 'Not Tutma',
                          value: r.toplamNot > 30 ? 1.0 : r.toplamNot / 30,
                          color: const Color(0xFFCE93D8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sekreter yorumu
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFFCE93D8).withOpacity(0.08), const Color(0xFF00E5A0).withOpacity(0.04)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFCE93D8).withOpacity(0.2)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('📅', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text('Aylık Değerlendirme', style: TextStyle(color: Color(0xFFCE93D8), fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(r.sekreterYorumu, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6)),
                      ],
                    ),
                  ),
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

class _MonthStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MonthStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}

class _PerformanceBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _PerformanceBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('%${(value * 100).toInt()}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}