import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';

/// Entidad de dominio que representa a un cliente en el ecosistema Koralis.
///
/// Modela los datos de contacto, identificación legal, notas u observaciones,
/// transacciones embebidas y estado operativo.
class Client {
  /// Identificador único del cliente en Cloud Firestore.
  final String id;

  /// Nombre completo de la persona o razón social de la empresa.
  final String nombre;

  /// Documento de identificación fiscal o legal (e.g. Cédula, DNI, RUT, NIT).
  final String documento;

  /// Correo electrónico de contacto principal.
  final String correo;

  /// Número telefónico de contacto.
  final String telefono;

  /// Notas u observaciones adicionales sobre el cliente o su negociación.
  final String observacion;

  /// Estado operativo del cliente (e.g. "Activo", "Inactivo", "Pendiente").
  final String estado;

  /// Fecha de registro o vinculación del cliente.
  final DateTime fechaCreacion;

  /// Historial de transacciones financieras registradas como subobjeto del cliente.
  final List<Transaction> transacciones;

  /// Identificador del usuario propietario al que pertenece este cliente en la arquitectura multiusuario.
  final String? userId;

  Client({
    required this.id,
    required this.nombre,
    required this.documento,
    required this.correo,
    required this.telefono,
    this.observacion = '',
    this.estado = 'Activo',
    this.transacciones = const [],
    DateTime? fechaCreacion,
    this.userId,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  /// Saldo monetario disponible del cliente calculado sumando ingresos y restando egresos.
  double get saldoDisponible =>
      transacciones.fold(0.0, (acum, t) => acum + t.valorFirmado);

  /// Crea una copia inmutable con modificaciones puntuales.
  Client copyWith({
    String? id,
    String? nombre,
    String? documento,
    String? correo,
    String? telefono,
    String? observacion,
    String? estado,
    List<Transaction>? transacciones,
    DateTime? fechaCreacion,
    String? userId,
  }) {
    return Client(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      documento: documento ?? this.documento,
      correo: correo ?? this.correo,
      telefono: telefono ?? this.telefono,
      observacion: observacion ?? this.observacion,
      estado: estado ?? this.estado,
      transacciones: transacciones ?? this.transacciones,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      userId: userId ?? this.userId,
    );
  }
}

