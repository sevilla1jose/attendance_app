/// Utilidades para validación de datos
class Validators {
  /// Valida un correo electrónico
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es obligatorio';
    }

    // Expresión regular para validar correos electrónicos
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegExp.hasMatch(value)) {
      return 'Ingresa un correo electrónico válido';
    }

    return null;
  }

  /// Valida una contraseña
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    return null;
  }

  /// Valida que dos contraseñas coincidan
  static String? validatePasswordsMatch(
      String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'La confirmación de contraseña es obligatoria';
    }

    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  /// Valida un campo de texto obligatorio
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'El campo ${fieldName ?? ''} es obligatorio';
    }

    return null;
  }

  /// Valida un número de teléfono
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // El teléfono puede ser opcional
    }

    // Expresión regular para validar teléfonos (formato básico)
    final phoneRegExp = RegExp(r'^\+?[0-9]{8,15}$');

    if (!phoneRegExp.hasMatch(value)) {
      return 'Ingresa un número de teléfono válido';
    }

    return null;
  }

  /// Valida que un valor sea numérico
  static String? validateNumeric(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null; // Puede ser opcional
    }

    // Expresión regular para validar números (enteros o decimales)
    final numericRegExp = RegExp(r'^-?[0-9]+(\.[0-9]+)?$');

    if (!numericRegExp.hasMatch(value)) {
      return 'El campo ${fieldName ?? ''} debe ser numérico';
    }

    return null;
  }

  /// Valida un rango numérico
  static String? validateNumericRange(
    String? value, {
    double? min,
    double? max,
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return null; // Puede ser opcional
    }

    final numericValidation = validateNumeric(value, fieldName: fieldName);
    if (numericValidation != null) {
      return numericValidation;
    }

    final numValue = double.parse(value);

    if (min != null && numValue < min) {
      return 'El valor debe ser mayor o igual a $min';
    }

    if (max != null && numValue > max) {
      return 'El valor debe ser menor o igual a $max';
    }

    return null;
  }

  /// Valida una fecha
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Puede ser opcional
    }

    try {
      final date = DateTime.parse(value);

      // Verificar que la fecha sea válida
      if (date.year < 1900 || date.year > 2100) {
        return 'Ingresa una fecha válida entre 1900 y 2100';
      }

      return null;
    } catch (e) {
      return 'Ingresa una fecha válida en formato YYYY-MM-DD';
    }
  }

  /// Valida que una fecha esté en el pasado
  static String? validatePastDate(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Puede ser opcional
    }

    final dateValidation = validateDate(value);
    if (dateValidation != null) {
      return dateValidation;
    }

    try {
      final date = DateTime.parse(value);
      final now = DateTime.now();

      if (date.isAfter(now)) {
        return 'La fecha debe estar en el pasado';
      }

      return null;
    } catch (e) {
      return 'Ingresa una fecha válida';
    }
  }

  /// Valida que una fecha esté en el futuro
  static String? validateFutureDate(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Puede ser opcional
    }

    final dateValidation = validateDate(value);
    if (dateValidation != null) {
      return dateValidation;
    }

    try {
      final date = DateTime.parse(value);
      final now = DateTime.now();

      if (date.isBefore(now)) {
        return 'La fecha debe estar en el futuro';
      }

      return null;
    } catch (e) {
      return 'Ingresa una fecha válida';
    }
  }

  /// Valida una URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Puede ser opcional
    }

    // Expresión regular para validar URLs
    final urlRegExp = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );

    if (!urlRegExp.hasMatch(value)) {
      return 'Ingresa una URL válida';
    }

    return null;
  }

  /// Valida un nombre o identificador
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es obligatorio';
    }

    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }

    return null;
  }

  /// Valida un identificador de usuario o código
  static String? validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'El código es obligatorio';
    }

    // Expresión regular para validar códigos alfanuméricos
    final codeRegExp = RegExp(r'^[a-zA-Z0-9_-]{3,20}$');

    if (!codeRegExp.hasMatch(value)) {
      return 'El código debe contener entre 3 y 20 caracteres alfanuméricos';
    }

    return null;
  }

  /// Valida una coordenada de latitud
  static String? validateLatitude(String? value) {
    if (value == null || value.isEmpty) {
      return 'La latitud es obligatoria';
    }

    final numericValidation = validateNumeric(value, fieldName: 'Latitud');
    if (numericValidation != null) {
      return numericValidation;
    }

    final lat = double.parse(value);
    if (lat < -90 || lat > 90) {
      return 'La latitud debe estar entre -90 y 90';
    }

    return null;
  }

  /// Valida una coordenada de longitud
  static String? validateLongitude(String? value) {
    if (value == null || value.isEmpty) {
      return 'La longitud es obligatoria';
    }

    final numericValidation = validateNumeric(value, fieldName: 'Longitud');
    if (numericValidation != null) {
      return numericValidation;
    }

    final lon = double.parse(value);
    if (lon < -180 || lon > 180) {
      return 'La longitud debe estar entre -180 y 180';
    }

    return null;
  }

  /// Valida un número de identificación
  static String? validateIdentification(String? value) {
    if (value == null || value.isEmpty) {
      return 'El número de identificación es obligatorio';
    }

    if (value.length < 5) {
      return 'El número de identificación debe tener al menos 5 caracteres';
    }

    return null;
  }
}
