import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WsClient {
  WebSocketChannel? _channel;
  final String url;
  Timer? _reconnectTimer;
  final _messageController = StreamController<dynamic>.broadcast();

  WsClient(this.url);

  Stream<dynamic> get stream => _messageController.stream;

  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        (message) {
          _messageController.add(message);
        },
        onDone: () {
          _reconnect();
        },
        onError: (error) {
          _reconnect();
        },
      );
    } catch (e) {
      _reconnect();
    }
  }

  void _reconnect() {
    _channel?.sink.close(status.goingAway);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      connect();
    });
  }

  void send(dynamic data) {
    if (_channel != null) {
      _channel!.sink.add(data);
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.normalClosure);
    if (!_messageController.isClosed) {
      _messageController.close();
    }
  }
}
