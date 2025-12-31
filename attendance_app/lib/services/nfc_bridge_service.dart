//nfc_bridge_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NfcBridgeService {
  static const String baseUrl = 'http://127.0.0.1:3001';

  // ✅ Singleton instance
  static final NfcBridgeService _instance = NfcBridgeService._internal();
  factory NfcBridgeService() => _instance;
  NfcBridgeService._internal();

  IO.Socket? _socket;
  StreamController<String>? _nfcStreamController;
  StreamController<Map<String, dynamic>>? _statusStreamController;
  bool _isSocketConnected = false;

  // Get NFC data stream
  Stream<String>? get nfcStream => _nfcStreamController?.stream;

  // Get status stream
  Stream<Map<String, dynamic>>? get statusStream =>
      _statusStreamController?.stream;

  // Check if connected
  bool get isConnected => _socket?.connected ?? false;

  // ✅ Get available COM ports
  static Future<List<String>> getAvailablePorts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/serial/ports'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ports = data['ports'] as List;
        return ports.map((p) => p['path'].toString()).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting ports: $e');
      }
      return [];
    }
  }

  // ✅ Get current connection status
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/serial/status'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'connected': data['connected'] ?? false,
          'port': data['port'],
          'lastNfcId': data['lastNfcId'],
        };
      }
      return {'connected': false};
    } catch (e) {
      print('❌ Error getting status: $e');
      return {'connected': false};
    }
  }

  // ✅ Get last NFC ID from server
  static Future<String?> getLastNfc() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/serial/last-nfc'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nfcId = data['nfcId'];

        // Validate NFC ID
        if (nfcId != null &&
            nfcId.toString().length == 10 &&
            RegExp(r'^[A-Za-z0-9]+$').hasMatch(nfcId.toString())) {
          return nfcId.toString();
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting last NFC: $e');
      return null;
    }
  }

  // ✅ Ensure Socket.IO is connected
  Future<void> _ensureSocketConnected() async {
    if (!_isSocketConnected ||
        _socket == null ||
        !(_socket?.connected ?? false)) {
      print('🔌 Socket.IO not connected, connecting...');
      await _connectWebSocket();
    } else {
      print('✅ Socket.IO already connected');
    }
  }

  // ✅ Connect to serial port
  Future<bool> connect(String port, {int baudRate = 9600}) async {
    try {
      // ✅ Ensure Socket.IO is connected FIRST
      await _ensureSocketConnected();

      // Then connect to serial port
      final response = await http.post(
        Uri.parse('$baseUrl/api/serial/connect'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'port': port,
          'baudRate': baudRate,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Serial port connected, Socket.IO active');
          return true;
        }
      }
      return false;
    } catch (e) {
      print('❌ Connection error: $e');
      return false;
    }
  }

  // ✅ Connect to Socket.IO (persistent connection)
  Future<void> _connectWebSocket() async {
    if (_isSocketConnected &&
        _socket != null &&
        (_socket?.connected ?? false)) {
      print('⚠️ Socket.IO already connected');
      return;
    }

    try {
      print('🔌 Connecting to Socket.IO: $baseUrl');

      // ✅ Create broadcast controllers if not exist
      _nfcStreamController ??= StreamController<String>.broadcast();
      _statusStreamController ??=
          StreamController<Map<String, dynamic>>.broadcast();

      // ✅ Configure Socket.IO
      _socket = IO.io(baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
      });

      // ✅ Connection event
      _socket!.on('connect', (_) {
        _isSocketConnected = true;
        print('✅ Socket.IO connected');
        print('🆔 Socket ID: ${_socket!.id}');
      });

      // ✅ NFC data event
      _socket!.on('nfc-data', (data) {
        try {
          print('📡 Socket.IO received NFC data: $data');
          final nfcId = data['nfcId'].toString();

          if (nfcId.length == 10 && RegExp(r'^[A-Za-z0-9]+$').hasMatch(nfcId)) {
            print('✅ Valid NFC ID: $nfcId');
            _nfcStreamController?.add(nfcId);
          } else {
            print('⚠️ Invalid NFC ID: $nfcId');
          }
        } catch (e) {
          print('❌ Error processing NFC data: $e');
        }
      });

      // ✅ NFC cleared event
      _socket!.on('nfc-cleared', (data) {
        print('🗑️ Socket.IO received NFC cleared: $data');
        _nfcStreamController?.add('NFC_CLEARED');
      });

      // ✅ Status update event
      _socket!.on('status', (data) {
        print('📊 Socket.IO status update: $data');
        _statusStreamController?.add(Map<String, dynamic>.from(data));
      });

      // ✅ Disconnect event
      _socket!.on('disconnect', (reason) {
        _isSocketConnected = false;
        print('❌ Socket.IO disconnected: $reason');
        _statusStreamController?.add({'connected': false});

        // ✅ Auto-reconnect after disconnect
        if (reason != 'io client disconnect') {
          print('🔄 Attempting to reconnect...');
          Future.delayed(const Duration(seconds: 2), () {
            if (!_isSocketConnected) {
              _connectWebSocket();
            }
          });
        }
      });

      // ✅ Connection error event
      _socket!.on('connect_error', (error) {
        print('❌ Socket.IO connection error: $error');
        _isSocketConnected = false;
      });

      print('✅ Socket.IO listeners setup complete');
    } catch (e) {
      print('❌ Socket.IO connection error: $e');
      _isSocketConnected = false;
    }
  }

  // ✅ Disconnect from serial port (but keep Socket.IO alive)
  Future<bool> disconnect() async {
    try {
      // ✅ DON'T close Socket.IO - keep it for next connection
      print('ℹ️ Disconnecting serial port, Socket.IO remains active');

      final response = await http.post(
        Uri.parse('$baseUrl/api/serial/disconnect'),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error disconnecting: $e');
      return false;
    }
  }

  // ✅ Complete cleanup (only call when app closes)
  void dispose() {
    print('🗑️ Disposing NFC Bridge Service completely');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _nfcStreamController?.close();
    _nfcStreamController = null;
    _statusStreamController?.close();
    _statusStreamController = null;
    _isSocketConnected = false;
  }
}
