// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _keyController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _testResult;
  bool? _aiAktif;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final data = await ApiService.getApiStatus();
      setState(() {
        _aiAktif = data['ai_aktif'] ?? false;
      });
    } catch (_) {}
  }

  Future<void> _saveKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      _showSnack('API key bos olamaz!');
      return;
    }
    setState(() { _loading = true; _testResult = null; });
    try {
      final result = await ApiService.setApiKey(key);
      setState(() {
        _testResult = result['test'] ?? 'Baglanti basarili!';
        _aiAktif = true;
      });
      _showSnack('AI aktif edildi! ✅');
    } catch (e) {
      setState(() { _testResult = 'Hata: $e'; _aiAktif = false; });
      _showSnack('Bir hata olustu');
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('AYARLAR', style: TextStyle(color: Color(0xFF00E5A0), fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('AI Asistan', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Groq AI\'ini bagla — tamamen ucretsiz! ⚡', style: TextStyle(color: Colors.white38, fontSize: 14)),
              const SizedBox(height: 28),

              if (_aiAktif != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (_aiAktif! ? const Color(0xFF00E5A0) : const Color(0xFFFF7043)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (_aiAktif! ? const Color(0xFF00E5A0) : const Color(0xFFFF7043)).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(_aiAktif! ? '✅' : '⚠️', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _aiAktif! ? 'AI aktif! Asistan gercek zamanli dusunuyor.' : 'AI bagli degil. API key gir.',
                          style: TextStyle(
                            color: _aiAktif! ? const Color(0xFF00E5A0) : const Color(0xFFFF7043),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

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
                        Text('🔑', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text('API Key Nereden Alinir?', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Step(no: '1', text: 'console.groq.com adresine git'),
                    _Step(no: '2', text: 'Hesap olustur veya giris yap'),
                    _Step(no: '3', text: 'Sol menuден "API Keys" a tikla'),
                    _Step(no: '4', text: '"Create Key" ile yeni key olustur'),
                    _Step(no: '5', text: 'gsk_... ile baslayan kodu kopyala'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

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
                        Text('🤖', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text('API Key Gir', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _keyController,
                      obscureText: _obscure,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'gsk_...',
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
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _saveKey,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5A0),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Text('AI\'i Aktifleştir 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_testResult != null)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF00E5A0).withOpacity(0.08), const Color(0xFF4FC3F7).withOpacity(0.04)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00E5A0).withOpacity(0.2)),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('🤖', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text('AI\'dan ilk mesaj:', style: TextStyle(color: Color(0xFF00E5A0), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_testResult!, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                    ],
                  ),
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String no;
  final String text;
  const _Step({required this.no, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5A0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF00E5A0).withOpacity(0.3)),
            ),
            child: Center(
              child: Text(no, style: const TextStyle(color: Color(0xFF00E5A0), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}