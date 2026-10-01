import 'package:flutter/material.dart';

/// Tipos de transacción soportados en el ecosistema Koralis.
enum TransactionType {
  /// Ingreso de dinero del cliente a la aplicación (aumenta el saldo disponible).
  recarga,

  /// Asignación de dinero disponible de un cliente a un instrumento (disminuye el saldo disponible).
  inversion,

  /// Cierre de un instrumento y retorno proporcional al cliente (aumenta el saldo disponible).
  retorno,

  /// Entrega o desembolso de dinero al cliente desde su disponible (disminuye el saldo disponible).
  retiro;

  /// Retorna si la transacción representa un ingreso (+ disponible) o una salida (- disponible).
  bool get esIngreso =>
      this == TransactionType.recarga || this == TransactionType.retorno;

  /// Símbolo algebraico que acompaña el valor monetario (+ o -).
  String get signo => esIngreso ? '+' : '-';

  /// Etiqueta en español para visualización en interfaz de usuario.
  String get etiqueta {
    switch (this) {
      case TransactionType.recarga:
        return 'Recarga';
      case TransactionType.inversion:
        return 'Inversión';
      case TransactionType.retorno:
        return 'Retorno';
      case TransactionType.retiro:
        return 'Retiro';
    }
  }

  /// Color semántico distintivo para badges y estados.
  Color get colorSugerido {
    switch (this) {
      case TransactionType.recarga:
        return const Color(0xFF10B981); // Esmeralda / Verde
      case TransactionType.inversion:
        return const Color(0xFF6366F1); // Índigo / Azul
      case TransactionType.retorno:
        return const Color(0xFF0EA5E9); // Celeste / Cian
      case TransactionType.retiro:
        return const Color(0xFFF59E0B); // Ámbar / Naranja
    }
  }

  /// Ícono representativo para la acción.
  IconData get icono {
    switch (this) {
      case TransactionType.recarga:
        return Icons.add_card_rounded;
      case TransactionType.inversion:
        return Icons.trending_up_rounded;
      case TransactionType.retorno:
        return Icons.account_balance_rounded;
      case TransactionType.retiro:
        return Icons.payments_outlined;
    }
  }

  /// Conversión segura desde string.
  static TransactionType fromString(String? raw) {
    if (raw == null) return TransactionType.recarga;
    final valorNormalizado = raw.trim().toLowerCase();
    for (final t in TransactionType.values) {
      if (t.name.toLowerCase() == valorNormalizado) {
        return t;
      }
    }
    return TransactionType.recarga;
  }
}

/// Entidad de dominio que representa un movimiento financiero en la cuenta de un cliente.
class Transaction {
  /// Identificador único del documento en Firestore.
  final String id;

  /// Identificador del cliente titular de la transacción.
  final String clienteId;

  /// Nombre del cliente (desnormalizado para visualización eficiente sin lecturas extra).
  final String clienteNombre;

  /// Tipo de movimiento financiero.
  final TransactionType tipo;

  /// Valor monetario absoluto de la transacción.
  final double valor;

  /// Fecha en que se efectuó la transacción.
  final DateTime fecha;

  /// Identificador o referencia opcional del instrumento (para inversiones y retornos).
  final String? instrumentoId;

  /// Observaciones o notas internas adicionales.
  final String observacion;

  /// Fecha de registro en el sistema.
  final DateTime fechaCreacion;

  Transaction({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.tipo,
    required this.valor,
    required this.fecha,
    this.instrumentoId,
    this.observacion = '',
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  /// Retorna el valor con el signo correspondiente (+/-).
  double get valorFirmado => tipo.esIngreso ? valor : -valor;

  /// Serialización a Map para Cloud Firestore.
  Map<String, dynamic> toMap() => {
        'id': id,
        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
        'tipo': tipo.name,
        'valor': valor,
        'fecha': fecha.millisecondsSinceEpoch,
        'instrumentoId': instrumentoId,
        'observacion': observacion,
        'fechaCreacion': fechaCreacion.millisecondsSinceEpoch,
      };

  /// Construcción desde Map de Firestore.
  factory Transaction.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parsearFecha(dynamic raw) {
      if (raw is int) {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      } else if (raw is String) {
        return DateTime.tryParse(raw) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final idFinal = (docId != null && docId.isNotEmpty)
        ? docId
        : (map['id'] as String? ?? '');

    return Transaction(
      id: idFinal,
      clienteId: map['clienteId'] as String? ?? '',
      clienteNombre: map['clienteNombre'] as String? ?? '',
      tipo: TransactionType.fromString(map['tipo'] as String?),
      valor: (map['valor'] as num?)?.toDouble() ?? 0.0,
      fecha: parsearFecha(map['fecha']),
      instrumentoId: map['instrumentoId'] as String?,
      observacion: map['observacion'] as String? ?? '',
      fechaCreacion: parsearFecha(map['fechaCreacion']),
    );
  }

  /// Crea una copia inmutable de la transacción con campos modificados.
  Transaction copyWith({
    String? id,
    String? clienteId,
    String? clienteNombre,
    TransactionType? tipo,
    double? valor,
    DateTime? fecha,
    String? instrumentoId,
    String? observacion,
    DateTime? fechaCreacion,
  }) {
    return Transaction(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      tipo: tipo ?? this.tipo,
      valor: valor ?? this.valor,
      fecha: fecha ?? this.fecha,
      instrumentoId: instrumentoId ?? this.instrumentoId,
      observacion: observacion ?? this.observacion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
