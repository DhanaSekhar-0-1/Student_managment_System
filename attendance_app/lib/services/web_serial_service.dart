import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

class WebSerialService {
  StreamController<String>? _dataController;

  // Check if Web Serial API is supported
  bool isSupported() {
    try {
      return js.context.hasProperty('serialBridge') &&
          js.context['serialBridge'].callMethod('isSupported');
    } catch (e) {
      print('Error checking support: $e');
      return false;
    }
  }

  // Request port (user must select)
  Future<bool> requestPort() async {
    try {
      final result = await js.context['serialBridge'].callMethod('requestPort');
      return result as bool;
    } catch (e) {
      print('Error requesting port: $e');
      return false;
    }
  }

  // Connect to selected port
  Future<bool> connect({int baudRate = 9600}) async {
    try {
      _dataController = StreamController<String>.broadcast();

      // Set up callback from JavaScript
      js.context['serialBridge'].callMethod('setDataCallback', [
        ((String data) {
          print('📡 Received from serial: $data');
          _dataController?.add(data);
        })
      ]);

      final result =
          await js.context['serialBridge'].callMethod('connect', [baudRate]);
      return result as bool;
    } catch (e) {
      print('Error connecting: $e');
      return false;
    }
  }

  // Disconnect
  Future<bool> disconnect() async {
    try {
      await js.context['serialBridge'].callMethod('disconnect');
      _dataController?.close();
      _dataController = null;
      return true;
    } catch (e) {
      print('Error disconnecting: $e');
      return false;
    }
  }

  // Get data stream
  Stream<String>? get dataStream => _dataController?.stream;

  // Dispose
  void dispose() {
    disconnect();
  }
}
