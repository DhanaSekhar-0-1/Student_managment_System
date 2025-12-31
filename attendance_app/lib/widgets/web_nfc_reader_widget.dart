// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../services/web_serial_service.dart';

class WebNfcReaderWidget extends StatefulWidget {
  final Function(String) onNfcReceived;

  const WebNfcReaderWidget({
    super.key,
    required this.onNfcReceived,
  });

  @override
  State<WebNfcReaderWidget> createState() => _WebNfcReaderWidgetState();
}

class _WebNfcReaderWidgetState extends State<WebNfcReaderWidget> {
  final WebSerialService _serialService = WebSerialService();
  bool _isSupported = false;
  bool _isConnected = false;
  String _status = 'Not connected';
  String? _lastNfcId;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🔧 Web NFC Reader Widget initialized (key: ${widget.key})');
    }
    if (kIsWeb) {
      _isSupported = _serialService.isSupported();
      if (!_isSupported) {
        _status =
            'Web Serial API not supported in this browser. Use Chrome or Edge.';
      }
    }
  }

  @override
  void didUpdateWidget(WebNfcReaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ NEW: Detect when widget key changes (form reset)
    if (widget.key != oldWidget.key) {
      print('🔄 Web NFC Reader Widget key changed, resetting state');
      setState(() {
        _lastNfcId = null; // ✅ Clear last NFC on rebuild
        if (_isConnected) {
          _status = 'Connected - Ready for new scan';
        }
      });
    }
  }

  Future<void> _requestAndConnect() async {
    if (!_isSupported) {
      _showMessage('Web Serial API not supported');
      return;
    }

    setState(() {
      _status = 'Requesting port...';
    });

    // User must select port
    final portSelected = await _serialService.requestPort();

    if (!portSelected) {
      setState(() {
        _status = 'No port selected';
      });
      return;
    }

    setState(() {
      _status = 'Connecting...';
    });

    final connected = await _serialService.connect(baudRate: 9600);

    if (connected) {
      setState(() {
        _isConnected = true;
        _status = 'Connected! Waiting for NFC...';
      });

      // Listen to data
      _serialService.dataStream?.listen((nfcId) {
        print('📡 NFC received in web widget: $nfcId');
        print('📋 Current _lastNfcId: $_lastNfcId');

        setState(() {
          _lastNfcId = nfcId;
          _status = 'NFC Detected: $nfcId';
        });

        widget.onNfcReceived(nfcId);
        _showMessage('NFC captured: $nfcId');

        print('✅ NFC passed to parent callback');
      });

      _showMessage('Connected to serial port');
    } else {
      setState(() {
        _status = 'Failed to connect';
      });
      _showMessage('Failed to connect');
    }
  }

  Future<void> _disconnect() async {
    await _serialService.disconnect();
    setState(() {
      _isConnected = false;
      _status = 'Disconnected';
      _lastNfcId = null;
    });
    _showMessage('Disconnected');
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  void dispose() {
    print('🗑️ Web NFC Reader Widget disposed');
    _serialService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Web Serial only works in web browsers'),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.nfc, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'NFC Reader (Web Serial API)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    _isConnected ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isConnected ? Colors.green : Colors.grey,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isConnected ? Icons.check_circle : Icons.info,
                    color: _isConnected ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _status,
                      style: TextStyle(
                        color: _isConnected
                            ? Colors.green.shade900
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Last NFC
            if (_lastNfcId != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Last NFC ID:',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(_lastNfcId!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Connect Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSupported
                    ? (_isConnected ? _disconnect : _requestAndConnect)
                    : null,
                icon: Icon(_isConnected ? Icons.link_off : Icons.link),
                label:
                    Text(_isConnected ? 'Disconnect' : 'Select Port & Connect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isConnected ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Instructions
            Text(
              _isSupported
                  ? '1. Click "Select Port & Connect"\n'
                      '2. Choose your ESP32 COM port\n'
                      '3. Allow access in browser popup\n'
                      '4. Scan NFC card\n'
                      '5. NFC ID will auto-fill'
                  : '⚠️ Please use Chrome or Edge browser',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _isSupported ? Colors.grey : Colors.red,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
