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
  // ═══════════════════════════════════════════════════════════════════
  // 🔧 CONFIGURATION - CHANGE THIS FOR YOUR NETWORK SETUP
  // ═══════════════════════════════════════════════════════════════════
  
  // ⚠️ IMPORTANT: Update this to your backend server's IP address!
  // This is the IP of the PC running your Node.js backend and MySQL
  static const String BACKEND_IP = '192.168.1.11';  // ← CHANGE THIS!
  static const String BACKEND_PORT = '3000';
  
  // Bridge server is LOCAL (on this Windows 7 machine with NFC reader)
  static const String BRIDGE_IP = 'localhost';
  static const String BRIDGE_PORT = '3001';
  
  // Built URLs
  static const String bridgeUrl = 'http://$BRIDGE_IP:$BRIDGE_PORT';
  static const String apiUrl = 'http://$BACKEND_IP:$BACKEND_PORT/api';
  
  // ═══════════════════════════════════════════════════════════════════

  IO.Socket? _socket;
  bool _isConnected = false;

  String _displayMessage = 'Ready to scan NFC cards...';
  String _studentName = '';
  bool _showSuccess = false;
  bool _showWarning = false;
  Color _displayColor = Colors.grey;
  Timer? _clearTimer;
  bool _isProcessing = false;

  int _totalScanned = 0;
  int _successCount = 0;
  int _errorCount = 0;
  final List<String> _recentScans = [];
  final List<String> _debugLog = [];

  @override
  void initState() {
    super.initState();
    _addDebugLog('🔧 NFC Attendance System - Initialized');
    _addDebugLog('');
    _addDebugLog('📡 NETWORK CONFIGURATION:');
    _addDebugLog('   Backend Server: $apiUrl');
    _addDebugLog('   Bridge Server:  $bridgeUrl (Local)');
    _addDebugLog('');
    _connectSocket();
    _testBackendConnection();
  }

  void _addDebugLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 23);
    print('[$timestamp] $message');
    setState(() {
      _debugLog.insert(0, '$timestamp - $message');
      if (_debugLog.length > 25) _debugLog.removeLast();
    });
  }

  // Test backend connection on startup
  Future<void> _testBackendConnection() async {
    _addDebugLog('🔍 Testing backend connection...');
    _addDebugLog('   Target: http://$BACKEND_IP:$BACKEND_PORT');
    
    try {
      final response = await http.get(
        Uri.parse('http://$BACKEND_IP:$BACKEND_PORT/'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        _addDebugLog('✅ Backend is reachable!');
        _addDebugLog('   Status: ${response.statusCode}');
      } else {
        _addDebugLog('⚠️ Backend responded with ${response.statusCode}');
      }
    } on TimeoutException {
      _addDebugLog('❌ Backend timeout - Cannot reach server');
      _addDebugLog('   Check if backend is running');
      _addDebugLog('   Check IP: $BACKEND_IP');
    } catch (e) {
      _addDebugLog('❌ Backend connection failed: $e');
      _addDebugLog('⚠️ Please verify:');
      _addDebugLog('   1. Backend IP is correct ($BACKEND_IP)');
      _addDebugLog('   2. Backend server is running');
      _addDebugLog('   3. Both PCs on same network');
      _addDebugLog('   4. Firewall allows port $BACKEND_PORT');
    }
  }

 void _connectSocket() {
  _addDebugLog('🔌 Connecting to local bridge server...');
  _addDebugLog('   Bridge URL: $bridgeUrl');

  try {
    _socket = IO.io(
      bridgeUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])   // ✅ REQUIRED
          .disableAutoConnect()           // ✅ REQUIRED
          .setTimeout(5000)               // ✅ SUPPORTED
          .build(),
    );

    _socket!.connect(); // ✅ explicit connect

    _socket!.onConnect((_) {
      _addDebugLog('✅ Bridge connected! Socket ID: ${_socket!.id}');
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
        _displayMessage = 'Bridge Disconnected!\nReconnecting...';
        _displayColor = Colors.red;
      });
    });

    _socket!.onConnectError((error) {
      _addDebugLog('❌ Bridge connection error: $error');
    });

    _socket!.on('nfc-data', (data) {
      _addDebugLog('📡 NFC data received from bridge');

      if (data is Map && data.containsKey('nfcId')) {
        final nfcId = data['nfcId'].toString();
        _addDebugLog('✅ NFC ID extracted: $nfcId');

        if (!_isProcessing) {
          _handleNfcScan(nfcId);
        }
      }
    });

  } catch (e) {
    _addDebugLog('❌ Socket setup error: $e');
  }
}


  Future<void> _handleNfcScan(String nfcId) async {
    if (_isProcessing) {
      _addDebugLog('⚠️ Already processing, skipping duplicate scan');
      return;
    }

    _isProcessing = true;
    _clearTimer?.cancel();

    setState(() {
      _totalScanned++;
      _displayMessage = 'Processing...';
      _studentName = '';
      _showSuccess = false;
      _showWarning = false;
      _displayColor = Colors.orange;
    });

    _addDebugLog('');
    _addDebugLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _addDebugLog('🔍 PROCESSING NFC SCAN');
    _addDebugLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _addDebugLog('📇 NFC ID: $nfcId');
    _addDebugLog('⏰ Time: ${DateTime.now().toString().substring(11, 19)}');

    try {
      _addDebugLog('');
      _addDebugLog('📤 Sending attendance request to backend...');
      _addDebugLog('   URL: $apiUrl/attendance/mark');
      _addDebugLog('   Backend: $BACKEND_IP:$BACKEND_PORT');
      _addDebugLog('   Method: POST');
      _addDebugLog('   Body: {"nfc_id":"$nfcId"}');
      
      final response = await http.post(
        Uri.parse('$apiUrl/attendance/mark'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'nfc_id': nfcId}),
      ).timeout(
        const Duration(seconds: 15), // Longer timeout for network requests
        onTimeout: () {
          throw TimeoutException('Backend request timed out after 15 seconds');
        },
      );

      _addDebugLog('');
      _addDebugLog('📥 Response received from backend');
      _addDebugLog('   Status Code: ${response.statusCode}');
      _addDebugLog('   Response Time: Network request completed');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        _addDebugLog('✅ Response parsed successfully');
        
        String studentName = 'Unknown Student';
        String status = 'PRESENT';
        String message = '';
        bool isSuccess = data['success'] ?? true;
        
        // Extract student information from response
        if (data['data'] != null) {
          if (data['data']['student_name'] != null) {
            studentName = data['data']['student_name'];
          } else if (data['data']['name'] != null) {
            studentName = data['data']['name'];
          }
          status = data['data']['status'] ?? 'PRESENT';
        } else if (data['student_name'] != null) {
          studentName = data['student_name'];
          status = data['status'] ?? 'PRESENT';
        }
        
        if (data['message'] != null) {
          message = data['message'];
        }
        
        _addDebugLog('');
        _addDebugLog('📊 EXTRACTED DATA:');
        _addDebugLog('   Student: $studentName');
        _addDebugLog('   Status: $status');
        _addDebugLog('   Message: $message');
        _addDebugLog('   Success: $isSuccess');
        
        // Check if attendance was already marked (duplicate)
        bool isDuplicate = message.toLowerCase().contains('already') ||
                          message.toLowerCase().contains('duplicate') ||
                          message.toLowerCase().contains('marked today') ||
                          !isSuccess;
        
        if (isDuplicate) {
          // ⚠️ DUPLICATE ATTENDANCE - Student already marked today
          _addDebugLog('');
          _addDebugLog('⚠️⚠️⚠️ DUPLICATE ATTENDANCE DETECTED ⚠️⚠️⚠️');
          _addDebugLog('   $studentName tried to scan again!');
          _addDebugLog('   Attendance was already recorded today');
          _addDebugLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          _addDebugLog('');

          setState(() {
            _studentName = studentName;
            _displayMessage = studentName.toUpperCase() + 
                            '\n\n⚠️ ATTENDANCE\nALREADY MARKED\nTODAY!';
            _showSuccess = false;
            _showWarning = true;
            _displayColor = Colors.orange.shade700;
            _errorCount++;
          });

          _recentScans.insert(0, '$studentName - ⚠️ Already Marked');
          if (_recentScans.length > 10) _recentScans.removeLast();

          // Keep warning visible for 5 seconds
          _clearTimer = Timer(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() {
                _displayMessage = 'Ready for next scan...';
                _studentName = '';
                _showSuccess = false;
                _showWarning = false;
                _displayColor = Colors.blue;
              });
              _addDebugLog('🔄 System ready for next scan');
            }
          });

        } else {
          // ✅ SUCCESS - New attendance marked
          _addDebugLog('');
          _addDebugLog('🎉🎉🎉 ATTENDANCE MARKED SUCCESSFULLY! 🎉🎉🎉');
          _addDebugLog('   Student: $studentName');
          _addDebugLog('   Status: $status');
          _addDebugLog('   Recorded in database');
          _addDebugLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          _addDebugLog('');

          setState(() {
            _studentName = studentName;
            _displayMessage = studentName.toUpperCase() + 
                            '\n\n✓ ' + status.toUpperCase();
            _showSuccess = true;
            _showWarning = false;
            _displayColor = status.toUpperCase() == 'PRESENT' 
                ? Colors.green.shade600
                : Colors.orange.shade600;
            _successCount++;
          });

          _recentScans.insert(0, '$studentName - $status');
          if (_recentScans.length > 10) _recentScans.removeLast();

          _clearTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _displayMessage = 'Ready for next scan...';
                _studentName = '';
                _showSuccess = false;
                _showWarning = false;
                _displayColor = Colors.blue;
              });
              _addDebugLog('🔄 System ready for next scan');
            }
          });
        }

        await Future.delayed(const Duration(milliseconds: 500));

      } else if (response.statusCode == 409) {
        // 409 Conflict - Duplicate attendance
        final data = json.decode(response.body);
        String studentName = 'Unknown';
        String message = data['message'] ?? 'Attendance already marked';
        
        if (data['data'] != null && data['data']['student_name'] != null) {
          studentName = data['data']['student_name'];
        }
        
        _addDebugLog('');
        _addDebugLog('⚠️ 409 CONFLICT - Duplicate Attendance');
        _addDebugLog('   Student: $studentName');
        _addDebugLog('   Already marked today');
        _addDebugLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        _addDebugLog('');

        setState(() {
          _studentName = studentName;
          _displayMessage = studentName.toUpperCase() + 
                          '\n\n⚠️ ATTENDANCE\nALREADY MARKED!';
          _showSuccess = false;
          _showWarning = true;
          _displayColor = Colors.orange.shade700;
          _errorCount++;
        });

        _recentScans.insert(0, '$studentName - ⚠️ Already Marked');
        if (_recentScans.length > 10) _recentScans.removeLast();

        _clearTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _displayMessage = 'Ready for next scan...';
              _studentName = '';
              _showSuccess = false;
              _showWarning = false;
              _displayColor = Colors.blue;
            });
          }
        });

        await Future.delayed(const Duration(milliseconds: 500));

      } else if (response.statusCode == 404) {
        // 404 - Student not found
        _addDebugLog('');
        _addDebugLog('❌ 404 - STUDENT NOT FOUND');
        _addDebugLog('   NFC ID: $nfcId');
        _addDebugLog('   Not registered in database');
        _addDebugLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        _addDebugLog('');

        setState(() {
          _studentName = nfcId;
          _displayMessage = 'STUDENT NOT FOUND\n\nNFC: $nfcId\n\nPlease register this card';
          _showSuccess = false;
          _showWarning = false;
          _displayColor = Colors.red;
          _errorCount++;
        });

        _clearTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() {
              _displayMessage = 'Ready for next scan...';
              _studentName = '';
              _showSuccess = false;
              _showWarning = false;
              _displayColor = Colors.blue;
            });
          }
        });

        await Future.delayed(const Duration(milliseconds: 500));

      } else {
        // Other error status codes
        throw Exception('Backend returned status ${response.statusCode}');
      }

    } on TimeoutException catch (e) {
      _addDebugLog('');
      _addDebugLog('⏰ TIMEOUT ERROR');
      _addDebugLog('   Backend did not respond in time');
      _addDebugLog('   Error: $e');
      _addDebugLog('');
      _addDebugLog('⚠️ TROUBLESHOOTING:');
      _addDebugLog('   1. Check backend server is running');
      _addDebugLog('   2. Verify IP address: $BACKEND_IP');
      _addDebugLog('   3. Check network connection');
      _addDebugLog('   4. Ping backend: ping $BACKEND_IP');
      _addDebugLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _addDebugLog('');

      setState(() {
        _studentName = '';
        _displayMessage = 'BACKEND TIMEOUT\n\nServer not responding\nCheck connection';
        _showSuccess = false;
        _showWarning = false;
        _displayColor = Colors.red;
        _errorCount++;
      });

      _clearTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _displayMessage = 'Ready for next scan...';
            _studentName = '';
            _showSuccess = false;
            _showWarning = false;
            _displayColor = Colors.blue;
          });
        }
      });

      await Future.delayed(const Duration(milliseconds: 500));

    } catch (e) {
      _addDebugLog('');
      _addDebugLog('❌ GENERAL ERROR');
      _addDebugLog('   Error: $e');
      _addDebugLog('   Type: ${e.runtimeType}');
      _addDebugLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _addDebugLog('');

      setState(() {
        _studentName = nfcId;
        _displayMessage = 'ERROR\n\n${e.toString()}';
        _showSuccess = false;
        _showWarning = false;
        _displayColor = Colors.red;
        _errorCount++;
      });

      _clearTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _displayMessage = 'Ready for next scan...';
            _studentName = '';
            _showSuccess = false;
            _showWarning = false;
            _displayColor = Colors.blue;
          });
        }
      });

      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      _isProcessing = false;
      _addDebugLog('🔓 Processing complete - Ready for next scan');
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
            // Header with network configuration display
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
                                'NFC Attendance System',
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
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

            // Main content area
            Expanded(
              child: Row(
                children: [
                  // Left - Main display
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
                            if (!_showSuccess && !_showWarning && _isConnected)
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
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Right - Debug log
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
                              } else if (log.contains('✅') || log.contains('SUCCESS') || log.contains('🎉')) {
                                textColor = Colors.green;
                              } else if (log.contains('⚠️') || log.contains('WARNING') || log.contains('DUPLICATE')) {
                                textColor = Colors.orange;
                              } else if (log.contains('📡') || log.contains('Backend') || log.contains('Network')) {
                                textColor = Colors.cyan;
                              } else if (log.contains('⏰') || log.contains('TIMEOUT')) {
                                textColor = Colors.red.shade300;
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

            // Recent scans footer
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
                        bool isDuplicate = scan.contains('Already Marked');
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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