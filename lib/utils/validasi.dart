class AppValidators {
  static String? validate(String? value, String fieldName) {
    final emptyCheck = isNotEmpty(value, fieldName);
    if (emptyCheck != null) {
      return emptyCheck;
    }

    final safeCheck = isSafeInput(value!);
    if (safeCheck != null) {
      return safeCheck;
    }

    return null;
  }

  /// Memvalidasi apakah input kosong atau hanya berisi spasi.
  static String? isNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong.';
    }
    return null;
  }

  /// Memvalidasi input dari karakter berbahaya untuk keamanan.
  static String? isSafeInput(String value) {
    final RegExp dangerousChars = RegExp(r'''['"`<>;&|$(){}[\]\\]''');

    if (dangerousChars.hasMatch(value)) {
      return 'Input mengandung karakter yang tidak diizinkan.';
    }

    return null;
  }

  /// Validator khusus untuk nama (hanya huruf dan spasi).
  static String? validateName(String? value, String fieldName) {
    final emptyCheck = isNotEmpty(value, fieldName);
    if (emptyCheck != null) {
      return emptyCheck;
    }

    final RegExp namePattern = RegExp(r'^[a-zA-Z\s]+$');

    if (!namePattern.hasMatch(value!)) {
      return '$fieldName hanya boleh mengandung huruf dan spasi.';
    }

    return null;
  }

  /// Validator khusus untuk format email.
  static String? validateEmail(String? value) {
    final emptyCheck = isNotEmpty(value, 'Email');
    if (emptyCheck != null) {
      return emptyCheck;
    }

    final RegExp emailPattern =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (!emailPattern.hasMatch(value!)) {
      return 'Format email tidak valid.';
    }

    return null;
  }

  /// Validator khusus untuk nomor telepon (format Indonesia).
  static String? validatePhone(String? value) {
    final emptyCheck = isNotEmpty(value, 'Nomor Telepon');
    if (emptyCheck != null) {
      return emptyCheck;
    }

    final RegExp phonePattern = RegExp(r'^(\+62|62|0?8)[0-9]{8,12}$');

    if (!phonePattern.hasMatch(value!)) {
      return 'Format nomor telepon tidak valid.';
    }

    return null;
  }

  /// Validator untuk password dengan kriteria panjang minimum, huruf, dan angka.
  static String? validatePassword(String? value) {
    final emptyCheck = isNotEmpty(value, 'Password');
    if (emptyCheck != null) {
      return emptyCheck;
    }

    if (value!.length < 8) {
      return 'Password minimal 8 karakter.';
    }

    final RegExp hasLetter = RegExp(r'[a-zA-Z]');
    final RegExp hasNumber = RegExp(r'[0-9]');

    if (!hasLetter.hasMatch(value) || !hasNumber.hasMatch(value)) {
      return 'Password harus mengandung huruf dan angka.';
    }

    return null;
  }
}