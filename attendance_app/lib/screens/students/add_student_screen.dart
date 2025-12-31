// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/nfc_reader_widget.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idNoController = TextEditingController();
  final _nameController = TextEditingController();
  final _pinNoController = TextEditingController();
  final _nfcIdController = TextEditingController();
  final _studentMobileController = TextEditingController();
  final _parentMobileController = TextEditingController();
  final _feesController = TextEditingController(text: '0');

  String? _selectedCollege;
  final List<String> _colleges = [
    'A.A.N.M.& V.V.R.S.R.',
    'Aditya Engineering of College',
    'DR YSR GOVT',
    'K.E.S POLYTECHNIC',
    'NUZIVID POLYTECHNIC',
    'SMT.B.SEETHA POLYTECHNIC',
    'Sri Vasavi Engineering college',
    'V.K.R & V.N.B Polytechnic College',
    'Vijaya Institute of technology for women',
    'Vikas polytechnic Visannapeta',
    'VKR,VNB & AGK COLLEGE',
  ];

  bool _isActive = true;
  bool _isLoading = false;
  bool _showNfcReader = true;

  // ✅ Key to force widget rebuild
  Key _nfcReaderKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('📱 Add Student Screen initialized');
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('🗑️ Add Student Screen disposed');
    }
    _idNoController.dispose();
    _nameController.dispose();
    _pinNoController.dispose();
    _nfcIdController.dispose();
    _studentMobileController.dispose();
    _parentMobileController.dispose();
    _feesController.dispose();
    super.dispose();
  }

  // ✅ Reset form
  void _resetForm() {
    if (kDebugMode) {
      print('🔄 Resetting form...');
    }

    _formKey.currentState?.reset();
    _idNoController.clear();
    _nameController.clear();
    _pinNoController.clear();
    _nfcIdController.clear();
    _studentMobileController.clear();
    _parentMobileController.clear();
    _feesController.text = '0';

    setState(() {
      _selectedCollege = null;
      _isActive = true;
      _nfcReaderKey = UniqueKey(); // ✅ Force rebuild
    });

    if (kDebugMode) {
      print('✅ Form reset complete');
    }
  }

  // ✅ Show popup after submission
  Future<void> _showAddAnotherDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Student Added!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Would you like to add another student?',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            // Close Button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close screen
              },
              child: const Text(
                'No, Close',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            // Add Another Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _resetForm(); // Reset form
              },
              icon: const Icon(Icons.add),
              label: const Text('Yes, Add Another'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleNfcReceived(String nfcId) {
    if (kDebugMode) {
      print('🎯 NFC received: $nfcId');
    }

    if (nfcId == 'NFC_CLEARED') {
      print('🗑️ Cleared signal, ignoring');
      return;
    }

    if (nfcId.length != 10 || !RegExp(r'^[A-Za-z0-9]+$').hasMatch(nfcId)) {
      if (kDebugMode) {
        print('⚠️ Invalid format: $nfcId');
      }
      return;
    }

    setState(() {
      _nfcIdController.text = nfcId;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ NFC ID captured: $nfcId'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Add Student',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'New Student',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Fill in the details below',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Student ID
              Text(
                'Student ID *',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _idNoController,
                decoration: const InputDecoration(
                  hintText: 'e.g., REG001',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Student ID is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Student Name
              Text(
                'Student Name *',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter full name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Student name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // PIN Number
              Text(
                'PIN Number *',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pinNoController,
                decoration: const InputDecoration(
                  hintText: 'e.g., PIN001',
                  prefixIcon: Icon(Icons.pin),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'PIN number is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // College Name
              Text(
                'College Name *',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCollege,
                decoration: const InputDecoration(
                  hintText: 'Select college',
                  prefixIcon: Icon(Icons.school),
                ),
                items: _colleges.map((college) {
                  return DropdownMenuItem(
                    value: college,
                    child: Text(
                      college,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCollege = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'College name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Student Mobile
              Text(
                'Student Mobile *',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentMobileController,
                decoration: const InputDecoration(
                  hintText: '10-digit mobile number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Student mobile is required';
                  }
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                    return 'Must be exactly 10 digits';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // NFC Reader Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NFC ID *',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showNfcReader = !_showNfcReader;
                      });
                    },
                    icon:
                        Icon(_showNfcReader ? Icons.visibility_off : Icons.nfc),
                    label: Text(_showNfcReader ? 'Hide Reader' : 'Show Reader'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // NFC Reader Widget
              if (_showNfcReader) ...[
                NfcReaderWidget(
                  key: _nfcReaderKey,
                  onNfcReceived: _handleNfcReceived,
                  initialPort: 'COM4',
                ),
                const SizedBox(height: 16),
              ],

              // NFC ID TextField
              TextFormField(
                controller: _nfcIdController,
                decoration: const InputDecoration(
                  hintText: '10-character alphanumeric',
                  prefixIcon: Icon(Icons.nfc),
                  helperText: 'Scanned from NFC Reader',
                ),
                maxLength: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'NFC ID is required';
                  }
                  if (value.length != 10) {
                    return 'Must be exactly 10 characters';
                  }
                  if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(value)) {
                    return 'Must be alphanumeric only';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Parent Mobile
              Text(
                'Parent Mobile *',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _parentMobileController,
                decoration: const InputDecoration(
                  hintText: '10-digit mobile number',
                  prefixIcon: Icon(Icons.phone_android),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Parent mobile is required';
                  }
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                    return 'Must be exactly 10 digits';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Fees Paid
              Text(
                'Fees Paid *',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _feesController,
                decoration: const InputDecoration(
                  hintText: 'Enter amount',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Fees amount is required';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Please enter a valid number';
                  }
                  if (amount < 0) {
                    return 'Fees cannot be negative';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Is Active Switch
              Card(
                child: SwitchListTile(
                  title: const Text('Active Status'),
                  subtitle: Text(
                      _isActive ? 'Student is active' : 'Student is inactive'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  activeTrackColor: AppTheme.success,
                ),
              ),

              const SizedBox(height: 32),

              // ✅ Single Submit Button
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  text: 'Add Student',
                  icon: Icons.add,
                  isLoading: _isLoading,
                  onPressed: _submitForm,
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Cancel',
                  isOutlined: true,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCollege == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a college'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final studentData = {
      'ID_No': _idNoController.text.trim(),
      'student_name': _nameController.text.trim(),
      'pin_no': _pinNoController.text.trim(),
      'college_name': _selectedCollege!,
      'student_mobile': _studentMobileController.text.trim(),
      'nfc_id': _nfcIdController.text.trim(),
      'parent_mobile': _parentMobileController.text.trim(),
      'fees_paid': double.tryParse(_feesController.text) ?? 0.0,
      'is_active': _isActive ? 1 : 0,
    };

    print(
        '📤 Submitting: ${studentData['student_name']} - ${studentData['nfc_id']}');

    final success =
        await context.read<StudentProvider>().createStudent(studentData);

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      print('✅ Student added successfully');

      // ✅ Show popup dialog
      await _showAddAnotherDialog();
    } else if (mounted) {
      final error = context.read<StudentProvider>().error;
      print('❌ Failed: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to add student'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}
