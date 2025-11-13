import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

typedef MessageCallback = void Function(Map<String, dynamic> message);
typedef ConversationUpdateCallback = void Function(Map<String, dynamic> lastMessage);

class ChatSocket {
  final String url; // e.g. 'http://localhost:8081/ws' or '/ws'
  final String userId;
  final Map<String, String>? connectHeaders; // e.g. {'Authorization':'Bearer ...'}
  StompClient? _stompClient;

  MessageCallback? onMessage; // when receiving a chat message for conversation detail
  ConversationUpdateCallback? onConversationUpdate; // when receiving last-message update for list

  ChatSocket({
    required this.url,
    required this.userId,
    this.connectHeaders,
    this.onMessage,
    this.onConversationUpdate,
  });

  void connect() {
    _stompClient = StompClient(
      config: StompConfig.SockJS(
        url: url,
        // headers used for initial WebSocket handshake
        webSocketConnectHeaders: connectHeaders,
        // headers used for STOMP CONNECT frame
        stompConnectHeaders: connectHeaders,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) => debugPrint('WS error: $error'),
        onStompError: (frame) => debugPrint('STOMP error: ${frame.body}'),
        onDisconnect: (frame) => debugPrint('STOMP disconnected'),
        // You can also provide heartbeat settings here if needed
      ),
    );
    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    debugPrint('STOMP connected: ${frame.headers}');

    // Subscribe for direct messages to this user
    // Backend often uses '/user/queue/messages' (server sends to user destinations)
    _stompClient!.subscribe(
      destination: '/user/queue/messages',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final raw = jsonDecode(frame.body!);
            final msg = _normalizeMessagePayload(raw);
            if (onMessage != null) onMessage!(msg);

            // send conversation update as convenience if payload has conversation info
            if (onConversationUpdate != null) {
              onConversationUpdate!( {
                'conversationId': msg['conversationId'],
                'content': msg['content'] ?? msg['text'],
                'senderId': msg['senderId'],
                'createdAt': msg['createdAt'],
              } );
            }
          } catch (e) {
            debugPrint('Error parsing message frame: $e');
          }
        }
      },
    );

    // Subscribe to a conversation-list update queue for the user if backend provides it
    _stompClient!.subscribe(
      destination: '/user/queue/conversations',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final raw = jsonDecode(frame.body!);
            final update = (raw is Map) ? Map<String, dynamic>.from(raw) : {'payload': raw};
            if (onConversationUpdate != null) onConversationUpdate!(update);
          } catch (e) {
            debugPrint('Error parsing conversation update: $e');
          }
        }
      },
    );

    // Optionally subscribe to a topic per-user (backend-dependent)
    _stompClient!.subscribe(
      destination: '/topic/conversations/$userId',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final raw = jsonDecode(frame.body!);
            final update = (raw is Map) ? Map<String, dynamic>.from(raw) : {'payload': raw};
            if (onConversationUpdate != null) onConversationUpdate!(update);
          } catch (e) {
            debugPrint('Error parsing topic update: $e');
          }
        }
      },
    );
  }

  Map<String, dynamic> _normalizeMessagePayload(dynamic raw) {
    // Ensure we return a map with common keys: id, conversationId, content/text, senderId, createdAt
    if (raw is Map) {
      return {
        'id': raw['id'] ?? raw['_id'] ?? raw['messageId'] ?? raw['msgId'],
        'conversationId': raw['conversationId'] ?? raw['conversation_id'] ?? raw['convId'] ?? raw['chatId'],
        'content': raw['content'] ?? raw['text'] ?? raw['body'] ?? raw['message'],
        'senderId': raw['senderId'] ?? raw['sender_id'] ?? raw['sender'],
        'createdAt': raw['createdAt'] ?? raw['created_at'] ?? raw['timestamp'] ?? raw['time'],
        // keep original payload if needed
        '_raw': raw,
      };
    } else {
      return {'content': raw.toString(), '_raw': raw};
    }
  }

  // send ack (delivered/read) to server handler at /app/ack
  void sendAck({required String messageId, required String type}) {
    final payload = jsonEncode({'messageId': messageId, 'type': type});
    _stompClient?.send(destination: '/app/ack', body: payload);
  }

  void disconnect() {
    try {
      _stompClient?.deactivate();
    } catch (e) {
      debugPrint('Error while disconnecting STOMP: $e');
    } finally {
      _stompClient = null;
    }
  }
}