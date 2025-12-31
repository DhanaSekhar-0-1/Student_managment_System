class Validators {
  // Validate required field
  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$field is required';
    }
    return null;
  }

  // Validate mobile number
  static String? mobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      return 'Must be exactly 10 digits';
    }
    return null;
  }

  // Validate NFC ID
  static String? nfcId(String? value) {
    if (value == null || value.isEmpty) {
      return 'NFC ID is required';
    }
    if (value.length != 16) {
      return 'NFC ID must be exactly 16 characters';
    }
    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(value)) {
      return 'NFC ID must be alphanumeric only';
    }
    return null;
  }

  // Validate email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  // Validate number
  static String? number(String? value, {String field = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$field is required';
    }
    if (double.tryParse(value) == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  // Validate minimum length
  static String? minLength(String? value, int length, {String field = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$field is required';
    }
    if (value.length < length) {
      return '$field must be at least $length characters';
    }
    return null;
  }

  // Validate maximum length
  static String? maxLength(String? value, int length, {String field = 'This field'}) {
    if (value != null && value.length > length) {
      return '$field must not exceed $length characters';
    }
    return null;
  }
}