import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';

import '../api_key.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _openAI = OpenAI.instance.build(
    token: kApiKey,
    baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
    enableLog: true,
  );
  final ChatUser _user = ChatUser(id: '1');
  final ChatUser _gpt = ChatUser(id: '2');
  final List<ChatMessage> _messages = [];
  final List<ChatUser> _loadResponse = [];

  Future<void> getResponse(ChatMessage message) async {
    setState(() {
      _messages.insert(0, message);
      _loadResponse.add(_gpt);
    });
    try {
      List<Map<String, dynamic>> history = _messages.reversed.map((message) {
        if (message.user == _user) {
          return Messages(role: Role.user, content: message.text).toJson();
        } else {
          return Messages(role: Role.assistant, content: message.text).toJson();
        }
      }).toList();
      final request = ChatCompleteText(
        model: GptTurboChatModel(),
        messages: history,
        maxToken: 200,
      );
      final response = await _openAI.onChatCompletion(request: request);
      for (var element in response!.choices) {
        if (element.message != null) {
          setState(() {
            _messages.insert(
                0,
                ChatMessage(
                    user: _gpt,
                    createdAt: DateTime.now(),
                    text: element.message!.content));
          });
        }
      }
    } catch (e) {
      _showErrorMessage(e);
      rethrow;
    } finally {
      setState(() {
        _loadResponse.remove(_gpt);
      });
    }
  }

  Future<dynamic> _showErrorMessage(e) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text('$e'),
          actions: <Widget>[
            TextButton(
              child: const Text('ОК'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black54,
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        title: const Text(
          'Chat with GPT',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: DashChat(
          typingUsers: _loadResponse,
          currentUser: _user,
          onSend: (ChatMessage message) {
            getResponse(message);
          },
          messages: _messages),
    );
  }
}
