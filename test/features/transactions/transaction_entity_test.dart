import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';

void main() {
  group('Transaction & TransactionType - Entidades y Reglas de Negocio', () {
    test('TransactionType debe reflejar correctamente si es ingreso o egreso y su signo', () {
      expect(TransactionType.recarga.esIngreso, isTrue);
      expect(TransactionType.recarga.signo, equals('+'));
      expect(TransactionType.recarga.etiqueta, equals('Recarga'));

      expect(TransactionType.retorno.esIngreso, isTrue);
      expect(TransactionType.retorno.signo, equals('+'));
      expect(TransactionType.retorno.etiqueta, equals('Retorno'));

      expect(TransactionType.inversion.esIngreso, isFalse);
      expect(TransactionType.inversion.signo, equals('-'));
      expect(TransactionType.inversion.etiqueta, equals('Inversión'));

      expect(TransactionType.retiro.esIngreso, isFalse);
      expect(TransactionType.retiro.signo, equals('-'));
      expect(TransactionType.retiro.etiqueta, equals('Retiro'));
    });

    test('TransactionType.fromString maneja nombres y fallback', () {
      expect(TransactionType.fromString('recarga'), equals(TransactionType.recarga));
      expect(TransactionType.fromString('INVERSION'), equals(TransactionType.inversion));
      expect(TransactionType.fromString('Retorno'), equals(TransactionType.retorno));
      expect(TransactionType.fromString('retiro'), equals(TransactionType.retiro));
      expect(TransactionType.fromString('desconocido'), equals(TransactionType.recarga));
      expect(TransactionType.fromString(null), equals(TransactionType.recarga));
    });

    test('Transaction.valorFirmado refleja el signo según el tipo de transacción', () {
      final tRecarga = Transaction(
        id: 'tx-1',
        clienteId: 'cli-1',
        clienteNombre: 'Carlos',
        tipo: TransactionType.recarga,
        valor: 1500000.0,
        fecha: DateTime(2026, 3, 1),
      );
      expect(tRecarga.valorFirmado, equals(1500000.0));

      final tInversion = Transaction(
        id: 'tx-2',
        clienteId: 'cli-1',
        clienteNombre: 'Carlos',
        tipo: TransactionType.inversion,
        valor: 500000.0,
        fecha: DateTime(2026, 3, 2),
        instrumentoId: 'CDT-001',
      );
      expect(tInversion.valorFirmado, equals(-500000.0));

      final tRetiro = Transaction(
        id: 'tx-3',
        clienteId: 'cli-1',
        clienteNombre: 'Carlos',
        tipo: TransactionType.retiro,
        valor: 200000.0,
        fecha: DateTime(2026, 3, 3),
      );
      expect(tRetiro.valorFirmado, equals(-200000.0));

      final tRetorno = Transaction(
        id: 'tx-4',
        clienteId: 'cli-1',
        clienteNombre: 'Carlos',
        tipo: TransactionType.retorno,
        valor: 550000.0,
        fecha: DateTime(2026, 3, 4),
        instrumentoId: 'CDT-001',
      );
      expect(tRetorno.valorFirmado, equals(550000.0));
    });

    test('Serialización toMap y fromMap preserva todos los campos', () {
      final fecha = DateTime(2026, 3, 15, 10, 30);
      final tx = Transaction(
        id: 'tx-100',
        clienteId: 'cli-88',
        clienteNombre: 'María Rodríguez',
        tipo: TransactionType.inversion,
        valor: 2000000.0,
        fecha: fecha,
        instrumentoId: 'CDT-2026-X',
        observacion: 'Asignación a CDT Bancolombia',
      );

      final map = tx.toMap();
      final rebuilt = Transaction.fromMap(map, 'tx-100');

      expect(rebuilt.id, equals('tx-100'));
      expect(rebuilt.clienteId, equals('cli-88'));
      expect(rebuilt.clienteNombre, equals('María Rodríguez'));
      expect(rebuilt.tipo, equals(TransactionType.inversion));
      expect(rebuilt.valor, equals(2000000.0));
      expect(rebuilt.fecha.millisecondsSinceEpoch, equals(fecha.millisecondsSinceEpoch));
      expect(rebuilt.instrumentoId, equals('CDT-2026-X'));
      expect(rebuilt.observacion, equals('Asignación a CDT Bancolombia'));
    });

    test('copyWith crea una copia con modificaciones puntuales', () {
      final tx = Transaction(
        id: 'tx-1',
        clienteId: 'cli-1',
        clienteNombre: 'Carlos',
        tipo: TransactionType.recarga,
        valor: 100000.0,
        fecha: DateTime(2026, 3, 1),
      );

      final updated = tx.copyWith(
        valor: 250000.0,
        observacion: 'Ajuste de recarga',
      );

      expect(updated.id, equals('tx-1'));
      expect(updated.clienteId, equals('cli-1'));
      expect(updated.valor, equals(250000.0));
      expect(updated.observacion, equals('Ajuste de recarga'));
      expect(updated.tipo, equals(TransactionType.recarga));
    });
  });
}
