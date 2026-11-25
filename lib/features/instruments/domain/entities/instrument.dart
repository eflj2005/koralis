/// Entidad que modela la participación porcentual de un cliente en un instrumento financiero.
class InstrumentClientShare {
  final String clienteId;
  final String clienteNombre;
  final double porcentajeParticipacion; // 0.0 - 100.0 %

  const InstrumentClientShare({
    required this.clienteId,
    required this.clienteNombre,
    required this.porcentajeParticipacion,
  });

  Map<String, dynamic> toMap() => {
        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
        'porcentajeParticipacion': porcentajeParticipacion,
      };

  factory InstrumentClientShare.fromMap(Map<String, dynamic> map) =>
      InstrumentClientShare(
        clienteId: map['clienteId'] as String? ?? '',
        clienteNombre: map['clienteNombre'] as String? ?? '',
        porcentajeParticipacion:
            (map['porcentajeParticipacion'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Entidad que representa un aporte de capital registrado en un instrumento financiero.
///
/// Mientras el instrumento permanece en estado `Borrador`, [transaccionId] es nulo y
/// el aporte no descuenta saldo disponible del cliente. Al guardar el instrumento como
/// `Activo`, se genera la transacción de inversión automática y se vincula su [transaccionId].
class InstrumentContribution {
  final String clienteId;
  final String clienteNombre;
  final double valor;
  final DateTime fecha;
  final String? transaccionId;

  InstrumentContribution({
    required this.clienteId,
    required this.clienteNombre,
    required this.valor,
    DateTime? fecha,
    this.transaccionId,
  }) : fecha = fecha ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
        'valor': valor,
        'fecha': fecha.millisecondsSinceEpoch,
        'transaccionId': transaccionId,
      };

  factory InstrumentContribution.fromMap(Map<String, dynamic> map) {
    DateTime parsearFecha(dynamic raw) {
      if (raw is int) {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      } else if (raw is String) {
        return DateTime.tryParse(raw) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return InstrumentContribution(
      clienteId: map['clienteId'] as String? ?? '',
      clienteNombre: map['clienteNombre'] as String? ?? '',
      valor: (map['valor'] as num?)?.toDouble() ?? 0.0,
      fecha: parsearFecha(map['fecha']),
      transaccionId: map['transaccionId'] as String?,
    );
  }

  InstrumentContribution copyWith({
    String? clienteId,
    String? clienteNombre,
    double? valor,
    DateTime? fecha,
    String? transaccionId,
    bool clearTransaccionId = false,
  }) {
    return InstrumentContribution(
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      valor: valor ?? this.valor,
      fecha: fecha ?? this.fecha,
      transaccionId:
          clearTransaccionId ? null : (transaccionId ?? this.transaccionId),
    );
  }
}

/// Entidad de dominio que representa un instrumento financiero en el ecosistema Koralis.
///
/// Encapsula datos de entrada obligatorios y reglas de cálculo automatizadas:
/// - [fechaCierre]: Calculada en base a [fechaApertura] y [dias].
/// - [valorRecibido]: [valorInvertido] + [rendimientoTProyec].
/// - [rendimientos]: [valorRecibido] - [valorInvertido].
/// - [retencionValor]: [rendimientos] * ([retencionPorcentaje] / 100).
/// - [valorFinalRend]: [rendimientos] - [retencionValor].
class Instrument {
  /// Identificador único del documento en Firestore.
  final String id;

  /// Número o código identificador del instrumento (e.g. "CDT-102030").
  final String numero;

  /// Nombre de la entidad financiera emisora o administradora (e.g. "Bancolombia").
  final String entidad;

  /// Fecha de apertura o colocación del instrumento.
  final DateTime fechaApertura;

  /// Plazo convenido expresado en días.
  final int dias;

  /// Tasa de interés efectiva anual pactada (% I.E.A.).
  final double tasaIea;

  /// Capital o valor monetario invertido.
  final double valorInvertido;

  /// Rendimiento proyectado según tasa y plazo convenidos.
  final double rendimientoTProyec;

  /// Porcentaje de retención en la fuente aplicable a los rendimientos.
  final double retencionPorcentaje;

  /// Observaciones o notas internas adicionales.
  final String observacion;

  /// Estado operativo del instrumento ('Borrador', 'Activo' o 'Cerrado').
  final String estado;

  /// Fecha de registro en el sistema.
  final DateTime fechaCreacion;

  /// Lista de clientes partícipes y su proporción asignada (preparado para fase multi-cliente).
  final List<InstrumentClientShare> participaciones;

  /// Lista de aportes de capital asociados al instrumento (diferidos hasta activación).
  final List<InstrumentContribution> aportes;

  /// Identificador del usuario propietario al que pertenece este instrumento en la arquitectura multiusuario.
  final String? userId;

  Instrument({
    required this.id,
    required this.numero,
    required this.entidad,
    required this.fechaApertura,
    required this.dias,
    required this.tasaIea,
    required this.valorInvertido,
    required this.rendimientoTProyec,
    this.retencionPorcentaje = 4.0,
    this.observacion = '',
    this.estado = 'Borrador',
    DateTime? fechaCreacion,
    this.participaciones = const [],
    this.aportes = const [],
    this.userId,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  // ---------------------------------------------------------------------------
  // Propiedades Calculadas de Negocio
  // ---------------------------------------------------------------------------

  /// Fecha estimada o definitiva de cierre/vencimiento ([fechaApertura] + [dias]).
  DateTime get fechaCierre => fechaApertura.add(Duration(days: dias));

  /// Valor total recibido al vencimiento ([valorInvertido] + [rendimientoTProyec]).
  double get valorRecibido => valorInvertido + rendimientoTProyec;

  /// Rendimientos brutos generados ([valorRecibido] - [valorInvertido]).
  double get rendimientos => valorRecibido - valorInvertido;

  /// Monto monetario retenido en fuente ([rendimientos] * [retencionPorcentaje] / 100).
  double get retencionValor =>
      double.parse((rendimientos * (retencionPorcentaje / 100.0)).toStringAsFixed(2));

  /// Rendimiento neto final recibido ([rendimientos] - [retencionValor]).
  double get valorFinalRend =>
      double.parse((rendimientos - retencionValor).toStringAsFixed(2));

  /// Crea una copia inmutable del instrumento con modificaciones puntuales.
  Instrument copyWith({
    String? id,
    String? numero,
    String? entidad,
    DateTime? fechaApertura,
    int? dias,
    double? tasaIea,
    double? valorInvertido,
    double? rendimientoTProyec,
    double? retencionPorcentaje,
    String? observacion,
    String? estado,
    DateTime? fechaCreacion,
    List<InstrumentClientShare>? participaciones,
    List<InstrumentContribution>? aportes,
    String? userId,
  }) {
    return Instrument(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      entidad: entidad ?? this.entidad,
      fechaApertura: fechaApertura ?? this.fechaApertura,
      dias: dias ?? this.dias,
      tasaIea: tasaIea ?? this.tasaIea,
      valorInvertido: valorInvertido ?? this.valorInvertido,
      rendimientoTProyec: rendimientoTProyec ?? this.rendimientoTProyec,
      retencionPorcentaje: retencionPorcentaje ?? this.retencionPorcentaje,
      observacion: observacion ?? this.observacion,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      participaciones: participaciones ?? this.participaciones,
      aportes: aportes ?? this.aportes,
      userId: userId ?? this.userId,
    );
  }
}
