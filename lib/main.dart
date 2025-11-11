import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drepto_biodevices/secure_storage_service.dart';

import 'pages/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

// Simple chat + call center support page
class ChatSupportPage extends StatefulWidget {
  const ChatSupportPage({super.key});

  @override
  State<ChatSupportPage> createState() => _ChatSupportPageState();
}

class _ChatSupportPageState extends State<ChatSupportPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _msgController = TextEditingController();
  final List<_Msg> _messages = [
    const _Msg(text: 'Hi! How can I help you today?', fromAi: true),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Msg(text: text, fromAi: false));
      _msgController.clear();
    });
    // Simulate AI response (replace with backend call)
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _messages.add(_Msg(text: _mockAiReply(text), fromAi: true));
    });
  }

  String _mockAiReply(String userText) {
    // TODO: Replace with real AI API integration
    return 'Thanks for your message: "$userText". Our assistant will get back to you shortly.';
  }

  Future<void> _callSupport() async {
    final uri = Uri(scheme: 'tel', path: '1800123456'); // Replace with your call center number
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot place a call on this device.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.smart_toy_outlined), text: 'Chatbot'),
            Tab(icon: Icon(Icons.call_outlined), text: 'Call Center'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Chatbot tab
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final m = _messages[i];
                    final align = m.fromAi ? Alignment.centerLeft : Alignment.centerRight;
                    final bg = m.fromAi ? Colors.grey.shade200 : const Color(0xFFE0F2F1);
                    final fg = Colors.black87;
                    return Align(
                      alignment: align,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(m.text, style: TextStyle(color: fg)),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF00897B)),
                      onPressed: _send,
                    )
                  ],
                ),
              ),
            ],
          ),

          // Call center tab
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Need to talk to a human?'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.call),
                  label: const Text('Call Support'),
                  onPressed: _callSupport,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool fromAi;
  const _Msg({required this.text, required this.fromAi});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drepto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF00B2A9), // Matched from logo
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF00B2A9), // Matched from logo
          secondary: const Color(0xFF4A148C), // Deep Purple
          tertiary: const Color(0xFF00B2A9), // Complementary color for accents
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B2A9), // Matched from logo
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
      ),
      builder: (context, child) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final double bottomOffset = bottomInset > 0 ? bottomInset + 16 : 80;
        return Stack(
          children: [
            if (child != null) child,
            Positioned(
              right: 16,
              bottom: bottomOffset,
              child: FutureBuilder<String?>(
                future: SecureStorageService.getToken(),
                builder: (context, snapshot) {
                  final hasToken = snapshot.connectionState == ConnectionState.done && snapshot.data != null;
                  if (!hasToken) return const SizedBox.shrink();
                  return FloatingActionButton.extended(
                    heroTag: 'globalChatbotFab',
                    backgroundColor: const Color(0xFF00897B),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Support'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChatSupportPage()),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      home: const SplashScreen(),
    );
  }
}
