// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final List<String>? tasks;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.tasks,
  });
}

class ChatScreen extends StatefulWidget {
  final List<ChatMessage> externalHistory;
  final void Function(List<ChatMessage>) onHistoryChanged;

  const ChatScreen({
    super.key,
    required this.externalHistory,
    required this.onHistoryChanged,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<ChatMessage> _messages;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.externalHistory.isEmpty) {
      // İlk açılış: karşılama mesajı
      _messages = [
        ChatMessage(
          text: 'Merhaba! Ben senin kişisel asistanınım 🤖\n\nBana ne yapmak istediğini söyle, görev listesi hazırlayayım. Ya da bugün ne yaptığını anlat, analiz edeyim!',
          isUser: false,
          time: DateTime.now(),
        ),
      ];
    } else {
      // Daha önce konuşma vardı, devam et
      _messages = List.from(widget.externalHistory);
    }
  }

  void _saveHistory() {
    widget.onHistoryChanged(List.from(_messages));
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, time: DateTime.now()));
      _isLoading = true;
    });
    _controller.clear();
    _saveHistory();
    _scrollToBottom();

    try {
      final history = _messages
          .where((m) => !(m == _messages.first && !m.isUser && _messages.first.text.startsWith('Merhaba!')))
          .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
          .toList();

      final result = await ApiService.chat(text, history);
      final aiText = result['cevap'] ?? 'Bir hata oluştu.';
      final List<String>? tasks = result['gorevler'] != null
          ? List<String>.from(result['gorevler'])
          : null;

      setState(() {
        _messages.add(ChatMessage(
          text: aiText,
          isUser: false,
          time: DateTime.now(),
          tasks: tasks,
        ));
        _isLoading = false;
      });
      _saveHistory();

      if (tasks != null && tasks.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) _showTaskConfirmDialog(tasks);
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Backend\'e bağlanılamadı 😅 Sunucunun çalıştığından emin ol.',
          isUser: false,
          time: DateTime.now(),
        ));
        _isLoading = false;
      });
      _saveHistory();
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showTaskConfirmDialog(List<String> tasks) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D0F14),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5A0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('📋', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Görev Listesi Hazır!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Projeye eklensin mi?', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...tasks.take(6).map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: Color(0xFF00E5A0), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                ],
              ),
            )),
            if (tasks.length > 6)
              Text('... ve ${tasks.length - 6} görev daha', style: const TextStyle(color: Colors.white24, fontSize: 12)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hayır', style: TextStyle(color: Colors.white38)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await ApiService.createProjectFromChat(tasks);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Görevler projeye eklendi! ✅', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              backgroundColor: const Color(0xFF00E5A0),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      } catch (_) {}
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5A0),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Evet, Ekle!', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) return _buildTypingIndicator();
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0C10),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5A0), Color(0xFF00B4D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kişisel Asistan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  CircleAvatar(radius: 4, backgroundColor: Color(0xFF00E5A0)),
                  SizedBox(width: 6),
                  Text('Çevrimiçi', style: TextStyle(color: Color(0xFF00E5A0), fontSize: 11)),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Sohbeti temizle butonu
          GestureDetector(
            onTap: () => _showClearConfirm(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.white38, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          // Hızlı komutlar
          GestureDetector(
            onTap: () => _showQuickCommands(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(Icons.bolt_rounded, color: Color(0xFF00E5A0), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D0F14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sohbeti Temizle', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text('Tüm konuşma geçmişi silinecek. Emin misin?', style: TextStyle(color: Colors.white54, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  text: 'Sohbet temizlendi. Yeni bir şeyler konuşalım! 🤖',
                  isUser: false,
                  time: DateTime.now(),
                ));
              });
              _saveHistory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  void _showQuickCommands() {
    final commands = [
      ('📊 Bugünkü durumumu analiz et', 'Bugün ne yaptığımı analiz et ve genel durumumu değerlendir.'),
      ('📋 Yeni görev listesi oluştur', 'Bana yeni bir görev listesi oluşturmamda yardım et.'),
      ('💡 Bugün ne yapmalıyım?', 'Bugün odaklanmam gereken görevleri söyle.'),
      ('🏆 Haftalık performansım nasıl?', 'Bu haftaki performansımı ve ilerlemi değerlendir.'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D0F14),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚡ Hızlı Komutlar', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...commands.map((c) => GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _controller.text = c.$2;
                _sendMessage();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Text(c.$1, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00E5A0), Color(0xFF00B4D8)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF00E5A0).withOpacity(0.15) : const Color(0xFF0D0F14),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(
                  color: isUser ? const Color(0xFF00E5A0).withOpacity(0.3) : Colors.white.withOpacity(0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00E5A0), Color(0xFF00B4D8)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0F14),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: const Row(
              children: [
                _DotAnimation(delay: 0),
                SizedBox(width: 4),
                _DotAnimation(delay: 200),
                SizedBox(width: 4),
                _DotAnimation(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0C10),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D0F14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Ne yapmak istiyorsun? Anlat...',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5A0), Color(0xFF00B4D8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5A0).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotAnimation extends StatefulWidget {
  final int delay;
  const _DotAnimation({required this.delay});

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: const CircleAvatar(radius: 4, backgroundColor: Color(0xFF00E5A0)),
    );
  }
}