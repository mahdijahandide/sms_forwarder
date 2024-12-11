// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_sms_listener/flutter_sms_listener.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isServiceEnabled = false;
  final TextEditingController _telegramTokenController =
      TextEditingController();
  final TextEditingController _telegramChatIdController =
      TextEditingController();
  final FlutterSmsListener _smsListener = FlutterSmsListener();
  late SharedPreferences prefs;


  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    prefs = await SharedPreferences.getInstance();
    // Initialize SharedPreferences

    // Load saved credentials
    setState(() {
      _telegramTokenController.text = prefs.getString('telegram_token') ?? '';
      _telegramChatIdController.text =  prefs.getString('telegram_chat_id') ?? '';
    });

    // Initialize SMS listener
    await _initializeSmsListener();
  }

  Future<void> _initializeSmsListener() async {
    // Request SMS permissions
    await _requestPermissions();

    // Initialize SMS listener
    _smsListener.onSmsReceived?.listen((SmsMessage message) async {
      if (_isServiceEnabled) {
        await _forwardSmsToTelegram(
            message.address ?? 'Unknown', message.body ?? '');
      }
    });
  }

  Future<void> _requestPermissions() async {
    // Request necessary permissions
    await Permission.sms.request();
    await Permission.phone.request();
  }

  Future<void> _saveTelegramCredentials() async {
    final String token = _telegramTokenController.text.trim();
    final String chatId = _telegramChatIdController.text.trim();

    if (token.isEmpty || chatId.isEmpty) {
      // Show error if fields are empty
      _showErrorDialog('Please enter both Token and Chat ID');
      return;
    }

    // Save to SharedPreferences
    await  prefs.setString('telegram_token', token);
    await  prefs.setString('telegram_chat_id', chatId);

    // Show success dialog
    _showSuccessDialog('Credentials saved successfully');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _forwardSmsToTelegram(String sender, String body) async {
    final String telegramToken =  prefs.getString('telegram_token') ?? '';
    final String telegramChatId =  prefs.getString('telegram_chat_id') ?? '';

    if (telegramToken.isEmpty || telegramChatId.isEmpty) {
      print('Telegram credentials not set');
      return;
    }

    final String message = 'From: $sender\nMessage: $body';
    final Uri url = Uri.parse(
        'https://api.telegram.org/bot$telegramToken/sendMessage?chat_id=$telegramChatId&text=${Uri.encodeComponent(message)}');

    try {
      final response = await http.get(url);
      print('Telegram message sent. Status: ${response.statusCode}');
    } catch (e) {
      print('Failed to send message to Telegram: $e');
    }
  }

  void _toggleService() {
    setState(() {
      _isServiceEnabled = !_isServiceEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _telegramTokenController,
                decoration: const InputDecoration(
                  labelText: 'Telegram Bot Token',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _telegramChatIdController,
                decoration: const InputDecoration(
                  labelText: 'Telegram Chat ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _saveTelegramCredentials,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Save Credentials'),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: _toggleService,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                              offset: const Offset(0, 0),
                              spreadRadius: 0,
                              blurRadius: 10,
                              color: Colors.grey.withOpacity(0.3))
                        ]),
                    child: Center(
                      child: Text(
                        _isServiceEnabled ? 'STOP' : 'START',
                        style: TextStyle(
                            color: _isServiceEnabled
                                ? Colors.redAccent
                                : Colors.greenAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _telegramTokenController.dispose();
    _telegramChatIdController.dispose();
    super.dispose();
  }
}
