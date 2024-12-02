import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ptuddnt/core/utils/hive.dart';
import 'package:ptuddnt/core/utils/token.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  StompClient? stompClient;
  List<Map<String, String>> messages = [];
  final userId = HiveService().getData('userData')['id'];
  final token = Token().get();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    print('duc111$userId  :   $token');
    stompClient = StompClient(
      config: StompConfig(
        url: 'ws://157.66.24.126:8080/ws',
        onConnect: _onConnect,
        onWebSocketError: (error) => print('WebSocket error: $error'),
      ),
    );
    stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    print('userId duc $userId');
    stompClient!.subscribe(
      destination: '/user/$userId/inbox',
      callback: (frame) {
        final body = jsonDecode(frame.body!);
        print('body $body');
        setState(() {
          messages.add({
            'sender': body['sender']['id'].toString(),
            'content': body['content'],
          });
        });
      },
    );
  }

  void _sendMessage() {
    final content = _contentController.text;
    stompClient!.send(
      destination: '/chat/message',
      body: jsonEncode({
        'receiver': {'id': 1}, // Change this as per requirement
        'content': content,
        'sender': userId,
        'token': token,
      }),
    );
    setState(() {
      messages.add({'sender': 'You', 'content': content});
    });
    _contentController.clear();
  }

  @override
  void dispose() {
    stompClient?.deactivate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isSent = message['sender'] == 'You';
                return Align(
                  alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSent ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(message['content']!),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _contentController, decoration: InputDecoration(hintText: 'Type a message'))),
                IconButton(icon: Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
