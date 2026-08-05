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

  /// Valida contraseña: min 6 caracteres, 1 mayúscula, 1 número
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña no puede estar vacía';
    }
    if (value.length < 6) {
      return 'Debe tener mínimo 6 caracteres';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener al menos una mayúscula';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un número';
    }
    return null;
  }
}
