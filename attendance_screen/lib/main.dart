import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(const NfcAttendanceApp());
}

class NfcAttendanceApp extends StatelessWidget {
  const NfcAttendanceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFC Attendance Marker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AttendanceMarkerScreen(),
    );
  }
}

class AttendanceMarkerScreen extends StatefulWidget {
  const AttendanceMarkerScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceMarkerScreen> createState() => _AttendanceMarkerScreenState();
}

class _AttendanceMarkerScreenState extends State<AttendanceMarkerScreen> {
  // ═══════════════════════════════════════════════════════════════
  // 🔧 CONFIGURATION
  // ═══════════════════════════════════════════════════════════════
  
  static const String BACKEND_IP = '192.168.1.11';
  static const String BACKEND_PORT = '3000';
  static const String BRIDGE_IP = 'localhost';
  static const String BRIDGE_PORT = '3001';
  
  static const String bridgeUrl = 'http://$BRIDGE_IP:$BRIDGE_PORT';
  static const String apiUrl = 'http://$BACKEND_IP:$BACKEND_PORT/api';
  
  // ═══════════════════════════════════════════════════════════════

  IO.Socket? _socket;
  bool _isConnected = false;
  bool _isSerialConnected = false;
  List<Map<String, dynamic>> _availablePorts = [];
  String? _selectedPort;
  bool _isLoadingPorts = false;

  String _displayMessage = 'Ready to scan NFC cards...';
  String _studentName = '';
  bool _showSuccess = false;
  bool _showWarning = false;
  Color _displayColor = Colors.grey;
  Timer? _clearTimer;

  int _totalScanned = 0;
  int _successCount = 0;
  int _errorCount = 0;
  int _queueLength = 0;
  String? _currentProcessing;
  
  final List<String> _recentScans = [];
  final List<String> _debugLog = [];

  @override
  void initState() {
    super.initState();
    _addDebugLog('🔧 NFC Attendance System - Queue Mode');
    _addDebugLog('');
    _addDebugLog('📡 NETWORK CONFIGURATION:');
    _addDebugLog('   Backend: $apiUrl');
    _addDebugLog('   Bridge: $bridgeUrl (Queue Processing)');
    _addDebugLog('');
    _connectSocket();
    _testBackendConnection();
  }

  void _addDebugLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 23);
    print('[$timestamp] $message');
    setState(() {
      _debugLog.insert(0, '$timestamp - $message');
      if (_debugLog.length > 30) _debugLog.removeLast();
    });
  }

  Future<void> _testBackendConnection() async {
    _addDebugLog('🔍 Testing backend connection...');
    
    try {
      final response = await http.get(
        Uri.parse('http://$BACKEND_IP:$BACKEND_PORT/'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        _addDebugLog('✅ Backend is reachable!');
      }
    } catch (e) {
      _addDebugLog('❌ Backend connection failed: $e');
    }
  }

  Future<void> _loadAvailablePorts() async {
    setState(() => _isLoadingPorts = true);

    _addDebugLog('🔍 Fetching available COM ports...');

    try {
      final response = await http.get(
        Uri.parse('$bridgeUrl/api/serial/ports'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['ports'] != null) {
          setState(() {
            _availablePorts = List<Map<String, dynamic>>.from(data['ports']);
          });
          _addDebugLog('✅ Found ${_availablePorts.length} ports');
        }
      }
    } catch (e) {
      _addDebugLog('❌ Failed to load ports: $e');
      _showSnackBar('Error loading ports: $e', isError: true);
    } finally {
      setState(() => _isLoadingPorts = false);
    }
  }

  Future<void> _connectToSerialPort(String port) async {
    _addDebugLog('🔌 Connecting to serial port: $port');

    try {
      final response = await http.post(
        Uri.parse('$bridgeUrl/api/serial/connect'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'port': port, 'baudRate': 9600}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _isSerialConnected = true;
            _selectedPort = port;
          });
          _addDebugLog('✅ Connected to $port!');
          _showSnackBar('Connected to $port', isError: false);
        }
      }
    } catch (e) {
      _addDebugLog('❌ Connection failed: $e');
      _showSnackBar('Failed to connect: $e', isError: true);
    }
  }

  Future<void> _disconnectFromSerialPort() async {
    _addDebugLog('🔌 Disconnecting...');

    try {
      final response = await http.post(
        Uri.parse('$bridgeUrl/api/serial/disconnect'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          _isSerialConnected = false;
          _selectedPort = null;
        });
        _addDebugLog('✅ Disconnected');
        _showSnackBar('Disconnected', isError: false);
      }
    } catch (e) {
      _addDebugLog('❌ Disconnect failed: $e');
    }
  }

  Future<void> _showPortSelectionDialog() async {
    await _loadAvailablePorts();

    if (_availablePorts.isEmpty) {
      _showSnackBar('No COM ports found', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select COM Port'),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availablePorts.length,
            itemBuilder: (context, index) {
              final port = _availablePorts[index];
              return ListTile(
                leading: const Icon(Icons.usb, color: Colors.blue),
                title: Text(
                  port['path'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${port['manufacturer'] ?? 'Unknown'}\n'
                  'VID: ${port['vendorId'] ?? 'N/A'}',
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _connectToSerialPort(port['path']);
                  },
                  child: const Text('Connect'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _connectSocket() {
    _addDebugLog('🔌 Connecting to bridge server...');

    try {
      _socket = IO.io(
        bridgeUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      _socket!.onConnect((_) {
        _addDebugLog('✅ Bridge connected!');
        setState(() {
          _isConnected = true;
          _displayMessage = 'Connected! Ready to scan...';
          _displayColor = Colors.blue;
        });
      });

      _socket!.onDisconnect((reason) {
        _addDebugLog('❌ Bridge disconnected: $reason');
        setState(() {
          _isConnected = false;
          _displayMessage = 'Disconnected!\nReconnecting...';
          _displayColor = Colors.red;
        });
      });

			  // ✅ ADD simple listener instead:
		_socket!.on('nfc-data', (data) {
		  _addDebugLog('📡 NFC data received: $data');
		  
		  try {
			if (data is Map && data.containsKey('nfcId')) {
			  final nfcId = data['nfcId'].toString();
			  _addDebugLog('✅ NFC ID extracted: $nfcId');
			  
			  // Process immediately (no queue)
			  _handleNfcScan(nfcId);
			} else {
			  _addDebugLog('❌ Invalid data format');
			}
		  } catch (e) {
			_addDebugLog('❌ Parse error: $e');
		  }
		});

      _socket!.onConnectError((error) {
        _addDebugLog('❌ Connection error: $error');
      });

    } catch (e) {
      _addDebugLog('❌ Socket error: $e');
    }
  }
  Future<void> _handleNfcScan(String nfcId) async {
  _clearTimer?.cancel();

  setState(() {
    _totalScanned++;
    _displayMessage = 'Processing...\n\nNFC: $nfcId';
    _displayColor = Colors.orange;
  });

  _addDebugLog('');
  _addDebugLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  _addDebugLog('🔍 PROCESSING NFC: $nfcId');
  _addDebugLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  try {
    _addDebugLog('📤 Sending to backend...');
    
    final response = await http.post(
      Uri.parse('$apiUrl/attendance/mark'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({'nfc_id': nfcId}),
    ).timeout(const Duration(seconds: 15));

    _addDebugLog('📥 Response: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      
      String studentName = 'Unknown';
      String status = 'PRESENT';
      bool isSuccess = data['success'] ?? true;
      
      if (data['data'] != null) {
        studentName = data['data']['student_name'] ?? 'Unknown';
        status = data['data']['status'] ?? 'PRESENT';
      }
      
      String message = data['message'] ?? '';
      bool isDuplicate = message.toLowerCase().contains('already') || !isSuccess;
      
      if (isDuplicate) {
        // ⚠️ DUPLICATE
        _addDebugLog('⚠️ DUPLICATE - Already marked');
        
        setState(() {
          _displayMessage = '⚠️ DUPLICATE!\n\n$studentName\n\nAlready marked today';
          _showSuccess = false;
          _showWarning = true;
          _displayColor = Colors.orange.shade700;
          _errorCount++;
        });

        _recentScans.insert(0, '$studentName - ⚠️ Duplicate');
        if (_recentScans.length > 10) _recentScans.removeLast();

        _clearTimer = Timer(const Duration(seconds: 4), _resetDisplay);
        
      } else {
        // ✅ SUCCESS
        _addDebugLog('✅ SUCCESS - $studentName - $status');
        
        setState(() {
          _studentName = studentName;
          _displayMessage = studentName.toUpperCase() + '\n\n✓ ' + status.toUpperCase();
          _showSuccess = true;
          _showWarning = false;
          _displayColor = status.toUpperCase() == 'PRESENT' 
              ? Colors.green.shade600
              : Colors.orange.shade600;
          _successCount++;
        });

        _recentScans.insert(0, '$studentName - $status');
        if (_recentScans.length > 10) _recentScans.removeLast();

        _clearTimer = Timer(const Duration(seconds: 3), _resetDisplay);
      }
      
    } else if (response.statusCode == 404) {
      // ❌ NOT FOUND
      _addDebugLog('❌ NOT FOUND - $nfcId');
      
      setState(() {
        _displayMessage = 'STUDENT NOT FOUND\n\nNFC: $nfcId';
        _showSuccess = false;
        _showWarning = false;
        _displayColor = Colors.red;
        _errorCount++;
      });

      _clearTimer = Timer(const Duration(seconds: 4), _resetDisplay);
    }

  } catch (e) {
    _addDebugLog('❌ ERROR: $e');
    
    setState(() {
      _displayMessage = 'ERROR\n\n$e';
      _showSuccess = false;
      _showWarning = false;
      _displayColor = Colors.red;
      _errorCount++;
    });

    _clearTimer = Timer(const Duration(seconds: 4), _resetDisplay);
  }
}

  void _handleNfcResult(Map<String, dynamic> data) {
    _clearTimer?.cancel();

    final nfcId = data['nfcId'];
    final success = data['success'] ?? false;
    final resultType = data['resultType'] ?? 'unknown';
    final studentName = data['studentName'] ?? 'Unknown';
    final status = data['status'] ?? 'PRESENT';
    final message = data['message'] ?? '';
    final statusCode = data['statusCode'] ?? 0;

    _addDebugLog('');
    _addDebugLog('📥 RESULT RECEIVED');
    _addDebugLog('   Type: $resultType');
    _addDebugLog('   Success: $success');
    _addDebugLog('   Status Code: $statusCode');

    setState(() {
      _totalScanned++;
      _currentProcessing = null;
    });

    if (resultType == 'success') {
      // ✅ SUCCESS
      _addDebugLog('✅ SUCCESS - $studentName - $status');
      
      setState(() {
        _studentName = studentName;
        _displayMessage = studentName.toUpperCase() + '\n\n✓ ' + status.toUpperCase();
        _showSuccess = true;
        _showWarning = false;
        _displayColor = Colors.green.shade600;
        _successCount++;
      });

      _recentScans.insert(0, '$studentName - $status');
      if (_recentScans.length > 10) _recentScans.removeLast();

      _clearTimer = Timer(const Duration(seconds: 3), _resetDisplay);
      
    } else if (resultType == 'duplicate') {
      // ⚠️ DUPLICATE
      _addDebugLog('⚠️ DUPLICATE - Already marked');
      
      setState(() {
        _displayMessage = '⚠️ DUPLICATE!\n\n$studentName\n\nAlready marked today';
        _showSuccess = false;
        _showWarning = true;
        _displayColor = Colors.orange.shade700;
        _errorCount++;
      });

      _recentScans.insert(0, '$studentName - ⚠️ Duplicate');
      if (_recentScans.length > 10) _recentScans.removeLast();

      _clearTimer = Timer(const Duration(seconds: 4), _resetDisplay);
      
    } else if (resultType == 'not_found') {
      // ❌ NOT FOUND
      _addDebugLog('❌ NOT FOUND - $nfcId');
      
      setState(() {
        _displayMessage = 'STUDENT NOT FOUND\n\nNFC: $nfcId\n\nPlease register';
        _showSuccess = false;
        _showWarning = false;
        _displayColor = Colors.red;
        _errorCount++;
      });

      _clearTimer = Timer(const Duration(seconds: 4), _resetDisplay);
      
    } else {
      // ❌ ERROR
      _addDebugLog('❌ ERROR - $message');
      
      setState(() {
        _displayMessage = 'ERROR\n\n$message';
        _showSuccess = false;
        _showWarning = false;
        _displayColor = Colors.red;
        _errorCount++;
      });

      _clearTimer = Timer(const Duration(seconds: 4), _resetDisplay);
    }
  }

  void _resetDisplay() {
    if (mounted) {
      setState(() {
        _displayMessage = 'Ready for next scan...';
        _studentName = '';
        _showSuccess = false;
        _showWarning = false;
        _displayColor = Colors.blue;
      });
      _addDebugLog('✅ Ready for next scan');
    }
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.nfc, color: Colors.white, size: 32),
                              SizedBox(width: 12),
                              Text(
                                'NFC Attendance - Queue Mode',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Backend: $BACKEND_IP:$BACKEND_PORT',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          if (_isSerialConnected && _selectedPort != null)
                            Text(
                              'Serial: $_selectedPort',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (_queueLength > 0)
                            Text(
                              '📊 Queue: $_queueLength waiting',
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: ElevatedButton.icon(
                              onPressed: _isSerialConnected
                                  ? _disconnectFromSerialPort
                                  : _showPortSelectionDialog,
                              icon: Icon(
                                _isSerialConnected ? Icons.link_off : Icons.usb,
                                size: 20,
                              ),
                              label: Text(
                                _isSerialConnected ? 'Disconnect' : 'Connect',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isSerialConnected
                                    ? Colors.red.shade600
                                    : Colors.green.shade600,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _isConnected
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isConnected ? Colors.green : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isConnected ? Icons.check_circle : Icons.cancel,
                                  color: _isConnected ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isConnected ? 'Connected' : 'Disconnected',
                                  style: TextStyle(
                                    color: _isConnected ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('Total', _totalScanned.toString(), Icons.credit_card),
                      _buildStatCard('Success', _successCount.toString(), Icons.check_circle),
                      _buildStatCard('Errors', _errorCount.toString(), Icons.error),
                    ],
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Row(
                children: [
                  // Display
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 600,
                        padding: const EdgeInsets.all(50),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _displayColor.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                          border: Border.all(color: _displayColor, width: 5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showSuccess 
                                  ? Icons.check_circle 
                                  : _showWarning 
                                      ? Icons.warning 
                                      : Icons.nfc,
                              size: 100,
                              color: _displayColor,
                            ),
                            const SizedBox(height: 30),
                            Text(
                              _displayMessage,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _displayColor,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_currentProcessing != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(_displayColor),
                                ),
                              ),
                            if (!_showSuccess && !_showWarning && _isConnected && _isSerialConnected && _currentProcessing == null)
                              const Padding(
                                padding: EdgeInsets.only(top: 20),
                                child: Text(
                                  'Place NFC card on reader',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            if (!_isSerialConnected)
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Text(
                                  '⚠️ Connect to COM port first',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Debug log
                  Container(
                    width: 450,
                    color: Colors.black87,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.black,
                          child: Row(
                            children: const [
                              Icon(Icons.terminal, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'LIVE DEBUG LOG',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _debugLog.length,
                            itemBuilder: (context, index) {
                              final log = _debugLog[index];
                              Color textColor = Colors.greenAccent;
                              
                              if (log.contains('❌') || log.contains('ERROR')) {
                                textColor = Colors.red;
                              } else if (log.contains('✅') || log.contains('SUCCESS')) {
                                textColor = Colors.green;
                              } else if (log.contains('⚠️')) {
                                textColor = Colors.orange;
                              } else if (log.contains('📡') || log.contains('Backend')) {
                                textColor = Colors.cyan;
                              } else if (log.contains('🔄') || log.contains('PROCESSING')) {
                                textColor = Colors.yellow;
                              }
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 1),
                                child: Text(
                                  log,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 11,
                                    fontFamily: 'Courier',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Recent scans
            if (_recentScans.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Scans:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: _recentScans.map((scan) {
                        bool isDuplicate = scan.contains('Duplicate');
                        return Chip(
                          avatar: Icon(
                            isDuplicate ? Icons.warning : Icons.check_circle,
                            color: isDuplicate ? Colors.orange : Colors.green,
                            size: 18,
                          ),
                          label: Text(scan),
                          backgroundColor: isDuplicate 
                              ? Colors.orange.shade50 
                              : Colors.green.shade50,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}