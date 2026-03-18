import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttIncomingMessage {
  final String topic;
  final String payload;

  const MqttIncomingMessage({required this.topic, required this.payload});
}

class MqttService {
  MqttService._internal();

  static final MqttService _instance = MqttService._internal();

  factory MqttService() => _instance;

  static const String broker = 'broker.hivemq.com';
  static const int port = 1883;
  static const String ledTopic = 'home/device1/led';
  static const String fanTopic = 'home/device1/fan';
  static const String sensorTopic = 'home/device1/sensor';

  final StreamController<MqttIncomingMessage> _messageController =
      StreamController<MqttIncomingMessage>.broadcast();

  MqttServerClient? _client;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  bool _manualDisconnect = false;

  Stream<MqttIncomingMessage> get messages => _messageController.stream;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<bool> connect() async {
    if (isConnected || _isConnecting) {
      return isConnected;
    }

    _isConnecting = true;
    _manualDisconnect = false;

    final String clientId =
        'family_assistant_${DateTime.now().millisecondsSinceEpoch}';

    final MqttServerClient client = MqttServerClient.withPort(
      broker,
      clientId,
      port,
    );
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;
    client.onDisconnected = _handleDisconnected;
    client.onConnected = _handleConnected;
    client.onSubscribed = _handleSubscribed;
    client.pongCallback = _handlePong;
    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    _client = client;

    try {
      await client.connect();
    } catch (_) {
      client.disconnect();
      _scheduleReconnect();
      _isConnecting = false;
      return false;
    }

    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      client.disconnect();
      _scheduleReconnect();
      _isConnecting = false;
      return false;
    }

    client.updates?.listen(_handleUpdates);
    _subscribeToSensorTopic();

    _isConnecting = false;
    return true;
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _client?.disconnect();
  }

  Future<void> publishLed(bool isOn) async {
    await _publish(topic: ledTopic, payload: isOn ? 'ON' : 'OFF');
  }

  Future<void> publishFan(bool isOn) async {
    await _publish(topic: fanTopic, payload: isOn ? 'ON' : 'OFF');
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _messageController.close();
  }

  Future<void> _publish({
    required String topic,
    required String payload,
  }) async {
    if (!isConnected) {
      final bool connected = await connect();
      if (!connected) {
        return;
      }
    }

    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client?.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }

  void _subscribeToSensorTopic() {
    if (!isConnected) {
      return;
    }

    _client?.subscribe(sensorTopic, MqttQos.atMostOnce);
  }

  void _handleUpdates(List<MqttReceivedMessage<MqttMessage?>>? updates) {
    if (updates == null || updates.isEmpty) {
      return;
    }

    for (final update in updates) {
      final message = update.payload;
      if (message is! MqttPublishMessage) {
        continue;
      }

      final String payload = MqttPublishPayload.bytesToStringAsString(
        message.payload.message,
      );

      _messageController.add(
        MqttIncomingMessage(topic: update.topic, payload: payload),
      );
    }
  }

  void _handleConnected() {
    _reconnectTimer?.cancel();
    _subscribeToSensorTopic();
  }

  void _handleDisconnected() {
    if (_manualDisconnect) {
      return;
    }

    _scheduleReconnect();
  }

  void _handleSubscribed(String topic) {}

  void _handlePong() {}

  void _scheduleReconnect() {
    if (_manualDisconnect || _reconnectTimer?.isActive == true) {
      return;
    }

    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      connect();
    });
  }
}
