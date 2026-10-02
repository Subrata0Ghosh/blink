import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Multiplayer game mode types
enum MultiplayerMode {
  sameDeviceDuel,
  localWifiP2P,
}

/// Challenge item for multiplayer rounds
class MultiplayerRoundData {
  final int roundNumber;
  final int seed;
  final int objectCount;
  final int changedIndex;
  final String shiftType; // 'color', 'shape', 'scale', 'position'

  const MultiplayerRoundData({
    required this.roundNumber,
    required this.seed,
    required this.objectCount,
    required this.changedIndex,
    required this.shiftType,
  });

  Map<String, dynamic> toJson() => {
        'roundNumber': roundNumber,
        'seed': seed,
        'objectCount': objectCount,
        'changedIndex': changedIndex,
        'shiftType': shiftType,
      };

  factory MultiplayerRoundData.fromJson(Map<String, dynamic> json) => MultiplayerRoundData(
        roundNumber: json['roundNumber'] as int? ?? 1,
        seed: json['seed'] as int? ?? 42,
        objectCount: json['objectCount'] as int? ?? 5,
        changedIndex: json['changedIndex'] as int? ?? 0,
        shiftType: json['shiftType'] as String? ?? 'color',
      );
}

/// Offline Peer-to-Peer & Same-Device Multiplayer Manager
class MultiplayerService extends ChangeNotifier {
  static final MultiplayerService _instance = MultiplayerService._internal();
  factory MultiplayerService() => _instance;
  MultiplayerService._internal();

  // Local duel state
  String p1Name = 'Player 1';
  String p2Name = 'Player 2';
  int p1Score = 0;
  int p2Score = 0;
  int currentRound = 1;
  int totalRounds = 3;
  bool isGameOver = false;

  // Network P2P state
  HttpServer? _server;
  WebSocket? _socket;
  bool isHost = false;
  bool isConnected = false;
  String? hostIpAddress;
  int serverPort = 8888;
  String opponentName = 'Opponent';

  StreamController<Map<String, dynamic>>? _messageStream;
  Stream<Map<String, dynamic>>? get onMessage => _messageStream?.stream;

  // ──────────────── SAME-DEVICE DUEL LOGIC ────────────────

  void startSameDeviceDuel({
    String player1 = 'Player 1',
    String player2 = 'Player 2',
    int rounds = 3,
  }) {
    p1Name = player1.trim().isEmpty ? 'Player 1' : player1.trim();
    p2Name = player2.trim().isEmpty ? 'Player 2' : player2.trim();
    p1Score = 0;
    p2Score = 0;
    currentRound = 1;
    totalRounds = rounds;
    isGameOver = false;
    notifyListeners();
  }

  MultiplayerRoundData generateRoundData(int round) {
    final rand = Random();
    final seed = rand.nextInt(100000);
    const objectCount = 5;
    final changedIndex = rand.nextInt(objectCount);
    const shiftTypes = ['color', 'shape', 'scale'];
    final shiftType = shiftTypes[rand.nextInt(shiftTypes.length)];

    return MultiplayerRoundData(
      roundNumber: round,
      seed: seed,
      objectCount: objectCount,
      changedIndex: changedIndex,
      shiftType: shiftType,
    );
  }

  void recordRoundResult({required int playerWinnerIndex}) {
    if (playerWinnerIndex == 1) {
      p1Score++;
    } else if (playerWinnerIndex == 2) {
      p2Score++;
    }

    final winTarget = (totalRounds / 2).ceil();
    if (p1Score >= winTarget || p2Score >= winTarget || currentRound >= totalRounds) {
      isGameOver = true;
    } else {
      currentRound++;
    }
    notifyListeners();
  }

  // ──────────────── LOCAL WI-FI / HOTSPOT P2P LOGIC ────────────────

  /// Find device's local IP address (Wi-Fi or Hotspot interface)
  static Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            // Prioritize standard local subnet IPs (192.168.x.x, 10.x.x.x, 172.x.x.x)
            if (addr.address.startsWith('192.168.') ||
                addr.address.startsWith('10.') ||
                addr.address.startsWith('172.')) {
              return addr.address;
            }
          }
        }
      }
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (e) {
      debugPrint('Error getting local IP: $e');
    }
    return null;
  }

  /// Start local WebSocket host server on Wi-Fi or Hotspot
  Future<String?> startHostRoom({
    required String myName,
    int port = 8888,
  }) async {
    await disconnect();

    p1Name = myName;
    isHost = true;
    serverPort = port;
    _messageStream = StreamController<Map<String, dynamic>>.broadcast();

    try {
      hostIpAddress = await getLocalIpAddress() ?? '127.0.0.1';
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      debugPrint('Multiplayer Host running on $hostIpAddress:$port');

      _server!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final ws = await WebSocketTransformer.upgrade(request);
          _socket = ws;
          isConnected = true;
          notifyListeners();

          _socket!.listen(
            (data) {
              try {
                final json = jsonDecode(data as String) as Map<String, dynamic>;
                _handleIncomingMessage(json);
              } catch (e) {
                debugPrint('Socket decode error: $e');
              }
            },
            onDone: () {
              isConnected = false;
              notifyListeners();
            },
            onError: (err) {
              isConnected = false;
              notifyListeners();
            },
          );

          // Send welcome handshake to client
          sendMessage({
            'type': 'handshake_ack',
            'hostName': p1Name,
          });
        } else {
          request.response
            ..statusCode = HttpStatus.ok
            ..write('BLINK Offline P2P Host Active')
            ..close();
        }
      });

      notifyListeners();
      return hostIpAddress;
    } catch (e) {
      debugPrint('Error starting P2P host: $e');
      await disconnect();
      return null;
    }
  }

  /// Connect to local host room via IP
  Future<bool> joinHostRoom({
    required String hostAddress,
    required String myName,
    int port = 8888,
  }) async {
    await disconnect();

    p2Name = myName;
    isHost = false;
    _messageStream = StreamController<Map<String, dynamic>>.broadcast();

    try {
      final cleanAddress = hostAddress.trim();
      final uri = Uri.parse('ws://$cleanAddress:$port/ws');
      _socket = await WebSocket.connect(uri.toString()).timeout(const Duration(seconds: 6));

      isConnected = true;
      notifyListeners();

      _socket!.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            _handleIncomingMessage(json);
          } catch (e) {
            debugPrint('Socket decode error: $e');
          }
        },
        onDone: () {
          isConnected = false;
          notifyListeners();
        },
        onError: (err) {
          isConnected = false;
          notifyListeners();
        },
      );

      // Send join message
      sendMessage({
        'type': 'join_request',
        'clientName': p2Name,
      });

      return true;
    } catch (e) {
      debugPrint('Error joining room: $e');
      await disconnect();
      return false;
    }
  }

  void sendMessage(Map<String, dynamic> msg) {
    if (_socket != null && isConnected) {
      try {
        _socket!.add(jsonEncode(msg));
      } catch (e) {
        debugPrint('Send message error: $e');
      }
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type == 'handshake_ack') {
      opponentName = msg['hostName'] as String? ?? 'Host';
      notifyListeners();
    } else if (type == 'join_request') {
      opponentName = msg['clientName'] as String? ?? 'Challenger';
      notifyListeners();
    }

    _messageStream?.add(msg);
  }

  Future<void> disconnect() async {
    try {
      await _socket?.close();
      await _server?.close(force: true);
      await _messageStream?.close();
    } catch (_) {}

    _socket = null;
    _server = null;
    _messageStream = null;
    isConnected = false;
    isHost = false;
    hostIpAddress = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
