// nfc_reader_widget.dart - MANUAL WITH PERSISTENT CONNECTION
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/nfc_bridge_service.dart';

class NfcReaderWidget extends StatefulWidget {
  final Function(String) onNfcReceived;

  const NfcReaderWidget({
    super.key,
    required this.onNfcReceived,
  });

  @override
  State<NfcReaderWidget> createState() => _NfcReaderWidgetState();
}

class _NfcReaderWidgetState extends State<NfcReaderWidget> {
  final NfcBridgeService _nfcService = NfcBridgeService();

  List<String> _availablePorts = [];
  String? _selectedPort;
  bool _isConnected = false;
  bool _isLoading = false;
  String? _lastNfcId;
  String _statusMessage = 'Select a port to connect';
  bool _hasAttemptedAutoConnect = false;

  static const String _lastPortKey = 'last_nfc_port';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('🗑️ NFC Reader Widget disposed (connection stays alive)');
    }
    // DON'T disconnect here - connection should persist!
    super.dispose();
  }

  // 🚀 Initialize widget
  Future<void> _initialize() async {
    // First, listen to NFC stream
    _listenToNfcStream();
    
    // Load available ports
    await _loadAvailablePorts();
    
    // Try to auto-reconnect to last port
    if (!_hasAttemptedAutoConnect) {
      _hasAttemptedAutoConnect = true;
      await _autoReconnect();
    }
  }

  // 🔄 Auto-reconnect to last used port
  Future<void> _autoReconnect() async {
    try {
      // Check if already connected
      final status = await NfcBridgeService.getStatus();
      
      if (status['connected'] == true) {
        final connectedPort = status['port'];
        setState(() {
          _isConnected = true;
          _selectedPort = connectedPort;
          _statusMessage = '✅ Already connected to $connectedPort';
        });
        
        if (kDebugMode) {
          print('✅ Already connected to: $connectedPort');
        }
        return;
      }

      // Not connected, try to reconnect to last saved port
      final lastPort = await _getSavedPort();
      
      if (lastPort != null && _availablePorts.contains(lastPort)) {
        if (kDebugMode) {
          print('🔄 Auto-reconnecting to saved port: $lastPort');
        }
        
        setState(() {
          _selectedPort = lastPort;
        });
        
        await _connect(silent: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Auto-reconnect failed: $e');
      }
    }
  }

  // 💾 Save port to SharedPreferences
  Future<void> _savePort(String port) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastPortKey, port);
      
      if (kDebugMode) {
        print('💾 Saved port: $port');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error saving port: $e');
      }
    }
  }

  // 📂 Get saved port from SharedPreferences
  Future<String?> _getSavedPort() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPort = prefs.getString(_lastPortKey);
      
      if (kDebugMode) {
        print('📂 Loaded saved port: $savedPort');
      }
      
      return savedPort;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error loading saved port: $e');
      }
      return null;
    }
  }

  // 📋 Load available COM ports
  Future<void> _loadAvailablePorts() async {
    setState(() {
      _isLoading = true;
      if (!_isConnected) {
        _statusMessage = 'Loading ports...';
      }
    });

    try {
      final ports = await NfcBridgeService.getAvailablePorts();
      
      if (kDebugMode) {
        print('📋 Available ports: $ports');
      }

      // Get saved port
      final savedPort = await _getSavedPort();

      setState(() {
        _availablePorts = ports;
        _isLoading = false;

        if (ports.isEmpty) {
          _statusMessage = 'No COM ports found. Check USB connection.';
        } else {
          // Auto-select saved port if available, otherwise first port
          if (savedPort != null && ports.contains(savedPort)) {
            _selectedPort = savedPort;
            if (!_isConnected) {
              _statusMessage = 'Last used: $savedPort - Click Connect';
            }
          } else if (_selectedPort == null) {
            _selectedPort = ports.first;
            if (!_isConnected) {
              _statusMessage = 'Select a port and click Connect';
            }
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading ports: $e');
      }
      
      setState(() {
        _isLoading = false;
        if (!_isConnected) {
          _statusMessage = 'Error loading ports. Is server running?';
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadAvailablePorts,
            ),
          ),
        );
      }
    }
  }

  // 🎧 Listen to NFC stream
  void _listenToNfcStream() {
    _nfcService.nfcStream?.listen(
      (nfcId) {
        if (kDebugMode) {
          print('📡 NFC received: $nfcId');
        }

        if (nfcId == 'NFC_CLEARED') {
          setState(() {
            _lastNfcId = null;
          });
          return;
        }

        if (nfcId.length == 10 && RegExp(r'^[A-Za-z0-9]+$').hasMatch(nfcId)) {
          setState(() {
            _lastNfcId = nfcId;
          });
          widget.onNfcReceived(nfcId);
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('❌ NFC Stream error: $error');
        }
      },
    );
  }

  // 🔌 Connect to selected port
  Future<void> _connect({bool silent = false}) async {
    if (_selectedPort == null) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a COM port'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting to $_selectedPort...';
    });

    try {
      final success = await _nfcService.connect(_selectedPort!);

      if (success) {
        // Save the successful port
        await _savePort(_selectedPort!);
      }

      setState(() {
        _isLoading = false;
        _isConnected = success;
        _statusMessage = success
            ? '✅ Connected to $_selectedPort'
            : '❌ Failed to connect to $_selectedPort';
      });

      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '✅ Connected to $_selectedPort'
                  : '❌ Connection failed',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }

      if (kDebugMode) {
        print(success ? '✅ Connected to $_selectedPort' : '❌ Connection failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Connection error: $e');
      }

      setState(() {
        _isLoading = false;
        _isConnected = false;
        _statusMessage = 'Connection error';
      });

      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔌 Disconnect
  Future<void> _disconnect() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Disconnecting...';
    });

    try {
      await _nfcService.disconnect();

      setState(() {
        _isLoading = false;
        _isConnected = false;
        _statusMessage = 'Disconnected. Click Connect to reconnect.';
        _lastNfcId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Disconnected'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Disconnect error: $e');
      }

      setState(() {
        _isLoading = false;
        _statusMessage = 'Disconnect error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isConnected 
                        ? Colors.green.shade100 
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.nfc,
                    color: _isConnected ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NFC Reader',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isConnected 
                              ? Colors.green 
                              : Colors.grey.shade700,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                // Refresh button
                IconButton(
                  onPressed: _isLoading || _isConnected 
                      ? null 
                      : _loadAvailablePorts,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh ports',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Port Selector Dropdown
            DropdownButtonFormField<String>(
              value: _selectedPort,
              decoration: InputDecoration(
                labelText: 'Select COM Port',
                prefixIcon: const Icon(Icons.usb),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                helperText: _availablePorts.isEmpty
                    ? 'No ports found - Click refresh'
                    : '${_availablePorts.length} port(s) available',
                helperStyle: TextStyle(
                  color: _availablePorts.isEmpty ? Colors.red : Colors.grey,
                  fontSize: 11,
                ),
              ),
              items: _availablePorts.isEmpty
                  ? [
                      const DropdownMenuItem(
                        value: null,
                        enabled: false,
                        child: Text('No ports available'),
                      ),
                    ]
                  : _availablePorts.map((port) {
                      return DropdownMenuItem(
                        value: port,
                        child: Text(port),
                      );
                    }).toList(),
              onChanged: _isConnected
                  ? null // Disable when connected
                  : (value) {
                      setState(() {
                        _selectedPort = value;
                        _statusMessage = value != null
                            ? 'Ready to connect to $value'
                            : 'Select a port';
                      });
                      
                      if (kDebugMode) {
                        print('📍 Selected port: $value');
                      }
                    },
            ),

            const SizedBox(height: 16),

            // Connect/Disconnect Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading || _availablePorts.isEmpty
                    ? null
                    : (_isConnected ? _disconnect : () => _connect()),
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_isConnected ? Icons.link_off : Icons.link),
                label: Text(
                  _isLoading
                      ? 'Processing...'
                      : (_isConnected ? 'Disconnect' : 'Connect'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isConnected ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // Last NFC ID Display
            if (_lastNfcId != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last Scanned',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _lastNfcId!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Instructions
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isConnected 
                    ? Colors.green.shade50 
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _isConnected ? Icons.check_circle_outline : Icons.info_outline,
                    color: _isConnected 
                        ? Colors.green.shade700 
                        : Colors.blue.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isConnected
                          ? 'Connected! Tap your NFC card on the reader to scan. Connection stays active even after submitting forms.'
                          : _availablePorts.isEmpty
                              ? '1. Connect NFC reader via USB\n2. Click refresh button\n3. Select port and connect'
                              : '1. Select COM port from dropdown\n2. Click Connect button\n3. Tap NFC card on reader',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isConnected 
                            ? Colors.green.shade900 
                            : Colors.blue.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}