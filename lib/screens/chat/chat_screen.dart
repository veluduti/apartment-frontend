import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/repositories/session_manager.dart';
import '../../core/services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String requestId;

  const ChatScreen({super.key, required this.requestId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  late IO.Socket socket;
  String? chatRoomId;

  Map<int, String> translatedMessages = {};
  Map<int, bool> translatingMessages = {};

  String selectedLanguage = "te";

  List messages = [];
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchChatRoom();
  }

  Future<void> translateMessage(
    int index,
    String message,
    String lang,
  ) async {

    setState(() {
      translatingMessages[index] = true;
    });

    final result = await ApiService.translateText(
      message,
      lang,
    );

    if (result != null) {
      setState(() {
        translatedMessages[index] = result;
      });
    }

    setState(() {
      translatingMessages[index] = false;
    });

  }

  Future<void> showLanguageSelector(
    int index,
    String message,
  ) async {

    final lang = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("English"),
                onTap: () => Navigator.pop(context, "en"),
              ),
              ListTile(
                title: const Text("Hindi"),
                onTap: () => Navigator.pop(context, "hi"),
              ),
              ListTile(
                title: const Text("Telugu"),
                onTap: () => Navigator.pop(context, "te"),
              ),
            ],
          ),
        );
      },
    );

    if (lang != null) {
      translateMessage(index, message, lang);
    }
  }

  Future<void> fetchChatRoom() async {

    final response = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/chat/${widget.requestId}"),
    );

    final data = jsonDecode(response.body);

    if (data["success"] == true) {

      setState(() {
        chatRoomId = data["data"]["id"];
        messages = data["data"]["messages"];
      });

      connectSocket();
    }
  }

  void connectSocket() {

    socket = IO.io(
      AppConfig.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      socket.emit("registerUser", SessionManager.userId);
      socket.emit("joinRoom", chatRoomId);
    });

    socket.on("receiveMessage", (data) {

      int existingIndex = messages.indexWhere(
            (m) =>
        m["senderId"].toString() ==
            data["senderId"].toString() &&
            m["message"] == data["message"] &&
            (m["isDeleted"] ?? false) == false,
      );

      if (existingIndex != -1) {

        setState(() {
          messages[existingIndex] = data;
        });

      } else {

        setState(() {
          messages.add(data);
        });

      }

      scrollToBottom();
    });

    socket.on("messageEdited", (data) {

      int index = messages.indexWhere((m) => m["id"] == data["id"]);

      if (index != -1) {

        setState(() {
          messages[index]["message"] = data["message"];
          messages[index]["isEdited"] = true;
        });
      }
    });

    socket.on("messageDeleted", (data) {

      int index = messages.indexWhere((m) => m["id"] == data["id"]);

      if (index != -1) {

        setState(() {
          messages[index]["message"] = "This message was deleted";
          messages[index]["isDeleted"] = true;
        });
      }
    });
  }

  Future<void> sendMessage() async {

    if (controller.text.trim().isEmpty) return;

    final messageText = controller.text.trim();

    controller.clear();

    final now = DateTime.now();

    final tempMessage = {
      "id": "temp_${now.millisecondsSinceEpoch}",
      "message": messageText,
      "senderId": SessionManager.userId,
      "isDeleted": false,
      "createdAt": now.toIso8601String(),
      "status": "sent"
    };

    setState(() {
      messages.add(tempMessage);
    });

    scrollToBottom();

    await http.post(
      Uri.parse("${AppConfig.baseUrl}/api/chat/send"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "requestId": widget.requestId,
        "senderId": SessionManager.userId,
        "message": messageText,
        "type": "TEXT"
      }),
    );
  }

  Future<void> deleteMessage(String messageId) async {

    int index = messages.indexWhere((m) => m["id"] == messageId);

    if (index != -1) {

      setState(() {
        messages[index]["message"] = "This message was deleted";
        messages[index]["isDeleted"] = true;
      });
    }

    await http.post(
      Uri.parse("${AppConfig.baseUrl}/api/chat/delete"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"messageId": messageId}),
    );
  }

  Future<void> editMessage(String messageId, String oldText) async {

    final editController = TextEditingController(text: oldText);

    final newText = await showDialog<String>(
      context: context,
      builder: (_) {

        return AlertDialog(
          title: const Text("Edit Message"),
          content: TextField(controller: editController),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, editController.text),
              child: const Text("Save"),
            )
          ],
        );
      },
    );

    if (newText != null && newText.isNotEmpty && newText != oldText) {

      await http.post(
        Uri.parse("${AppConfig.baseUrl}/api/chat/edit"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "messageId": messageId,
          "newMessage": newText
        }),
      );
    }
  }

  void scrollToBottom() {

    Future.delayed(const Duration(milliseconds: 100), () {

      if (scrollController.hasClients) {

        scrollController.jumpTo(
          scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  String formatMessageTime(String? time) {

    if (time == null) return "";

    final dateTime = DateTime.tryParse(time);

    if (dateTime == null) return "";

    int hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');

    String ampm = "AM";

    if (hour >= 12) {
      ampm = "PM";
      if (hour > 12) {
        hour = hour - 12;
      }
    }

    if (hour == 0) {
      hour = 12;
    }

    return "$hour:$minute $ampm";
  }

  Widget buildStatusIcon(String? status) {

    if (status == "seen") {
      return const Icon(Icons.done_all, size: 14, color: Color(0xFF34B7F1));
    }

    if (status == "delivered") {
      return const Icon(Icons.done_all, size: 14, color: Colors.grey);
    }

    return const Icon(Icons.done, size: 14, color: Colors.grey);
  }

  @override
  void dispose() {

    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFE5DDD5),

      appBar: AppBar(
        title: const Text("Chat"),
      ),

      body: Column(
        children: [

          Expanded(

            child: ListView.builder(

              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              itemCount: messages.length,

              itemBuilder: (_, index) {

                final msg = messages[index];

                final isMe =
                    msg["senderId"] == SessionManager.userId;

                return Align(

                  alignment:
                  isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,

                  child: ConstrainedBox(

                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),

                                   
                    child: GestureDetector(
  onLongPress: () async {

  if (!isMe || (msg["isDeleted"] ?? false)) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit"),
                onTap: () {
                  Navigator.pop(context, "edit");
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Delete"),
                onTap: () {
                  Navigator.pop(context, "delete");
                },
              ),

            ],
          ),
        );
      },
    );

    if (selected == "edit") {
      editMessage(
        msg["id"],
        msg["message"],
      );
    }

    if (selected == "delete") {
      deleteMessage(msg["id"]);
    }

  },

  child: Container(

                      margin: const EdgeInsets.symmetric(vertical: 3),

                      padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6
                      ),

                      decoration: BoxDecoration(

                        color: isMe
                            ? const Color(0xFFDCF8C6)
                            : Colors.white,

                        borderRadius: BorderRadius.circular(7),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                          )
                        ],

                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Stack(
                            children: [

                              Padding(
                                padding: const EdgeInsets.only(right: 60, bottom: 16),
                                child: Text(
                                  msg["message"],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Row(
                                  children: [

                                    if (msg["isEdited"] == true)
                                      const Text(
                                        "edited ",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),

                                    Text(
                                      formatMessageTime(msg["createdAt"]),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey,
                                      ),
                                    ),

                                    if (isMe)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 3),
                                        child: buildStatusIcon(msg["status"]),
                                      ),

                                  ],
                                ),
                              ),

                            ],
                          ),

                          if (!isMe && !(msg["isDeleted"] ?? false))
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: GestureDetector(
                                onTap: () {
                                  showLanguageSelector(
                                      index,
                                      msg["message"]
                                  );
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.translate,
                                      size: 12,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      "Translate",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (translatedMessages[index] != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                translatedMessages[index]!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),

                        ],
                      ),
                    ),
                  ),
                  ),
                );
              },
            ),
          ),

          Container(

            padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6
            ),

            color: Colors.white,

            child: Row(

              children: [

                Expanded(

                  child: TextField(

                    controller: controller,

                    decoration: InputDecoration(

                      hintText: "Type message...",

                      filled: true,

                      fillColor: const Color(0xFFF0F0F0),

                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                CircleAvatar(

                  backgroundColor: const Color(0xFF128C7E),

                  child: IconButton(

                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),

                    onPressed: sendMessage,

                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}