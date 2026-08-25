class CoreValidators {
  /// Valida que el correo tenga un formato correcto
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo no puede estar vacío';
    }
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value.trim())) {
      return 'Ingrese un correo electrónico válido';
    }
    return null;
  }

  /// Valida contraseña: min 6 caracteres, al menos 1 mayúscula (soporta Ñ y acentos) y 1 número
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña no puede estar vacía';
    }
    if (value.length < 6) {
      return 'Debe tener mínimo 6 caracteres';
    }
    // Soporte para mayúsculas en español incluyendo Ñ y tildes
    if (!value.contains(RegExp(r'[A-ZÁÉÍÓÚÑ]'))) {
      return 'Debe contener al menos una mayúscula';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un número';
    }
    return null;
  }
}
