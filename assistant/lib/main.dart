// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/daily_analysis_screen.dart';
import 'screens/weekly_report_screen.dart';
import 'screens/monthly_report_screen.dart';
import 'screens/create_project_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/chat_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Asistan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A0C10),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5A0),
          surface: Color(0xFF0D0F14),
        ),
      ),
      home: const HomeScreen(),
      routes: {
        '/create': (ctx) => const CreateProjectScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Chat geçmişi burada yaşıyor — sekme değişse sıfırlanmaz
  final List<ChatMessage> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _checkNotifications();
  }

  Future<void> _checkNotifications() async {
    await Future.delayed(const Duration(seconds: 1));
    try {
      final data = await ApiService.checkNotifications();
      if (data['bildirim_var'] == true && mounted) {
        final bildirimler = data['bildirimler'] as List;
        for (final b in bildirimler) {
          await _showNotificationDialog(b);
        }
      }
    } catch (_) {}
  }

  Future<void> _showNotificationDialog(Map<String, dynamic> b) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D0F14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          b['baslik'] ?? '',
          style: const TextStyle(color: Color(0xFF00E5A0), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b['mesaj'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5A0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00E5A0).withOpacity(0.2)),
              ),
              child: Text(b['detay'] ?? '', style: const TextStyle(color: Color(0xFF00E5A0), fontSize: 13)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() { _selectedIndex = b['tip'] == 'aylik' ? 3 : 2; });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5A0),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Raporu Gör', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack: tüm ekranlar arka planda yaşar, sekme değişince state sıfırlanmaz!
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const DailyAnalysisScreen(),
          ChatScreen(
            externalHistory: _chatHistory,
            onHistoryChanged: (msgs) {
              _chatHistory.clear();
              _chatHistory.addAll(msgs);
            },
          ),
          const WeeklyReportScreen(),
          const MonthlyReportScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F14),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF00E5A0),
          unselectedItemColor: Colors.white38,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.today_rounded), label: 'Bugün'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Asistan'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Haftalık'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Aylık'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Ayarlar'),
          ],
        ),
      ),
    );
  }
}