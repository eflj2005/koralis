import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';

void main() {
  group('Instrument Entity - Pruebas de cálculos financieros y copyWith', () {
    final apertura = DateTime(2026, 1, 15);
    final instrument = Instrument(
      id: 'inst-001',
      numero: 'CDT-2026-889',
      entidad: 'Bancolombia S.A.',
      fechaApertura: apertura,
      dias: 90,
      tasaIea: 12.50,
      valorInvertido: 10000000.0, // 10 millones
      rendimientoTProyec: 300000.0, // 300 mil
      retencionPorcentaje: 7.0, // 7%
      observacion: 'Inversión CDT a 90 días',
      participaciones: const [
        InstrumentClientShare(
          clienteId: 'c1',
          clienteNombre: 'Juan Perez',
          porcentajeParticipacion: 100.0,
        ),
      ],
    );

    test('Fecha Cierre debe ser calculada correctamente sumando los días a la fecha de apertura', () {
      final expectedCierre = apertura.add(const Duration(days: 90));
      expect(instrument.fechaCierre, equals(expectedCierre));
    });

    test('Valor Recibido debe ser igual a Valor Invertido + Rendimiento T. Proyec.', () {
      // 10,000,000 + 300,000 = 10,300,000
      expect(instrument.valorRecibido, equals(10300000.0));
    });

    test('Rendimientos debe ser igual a Valor Recibido - Valor Invertido', () {
      // 10,300,000 - 10,000,000 = 300,000
      expect(instrument.rendimientos, equals(300000.0));
    });

    test('Retención \$ debe ser calculada como Rendimientos * (Retencion % / 100)', () {
      // 300,000 * 0.07 = 21,000
      expect(instrument.retencionValor, equals(21000.0));
    });

    test('Valor Final Rend. debe ser igual a Rendimientos - Retención \$', () {
      // 300,000 - 21,000 = 279,000
      expect(instrument.valorFinalRend, equals(279000.0));
    });

    test('InstrumentClientShare toMap y fromMap serializan correctamente', () {
      const share = InstrumentClientShare(
        clienteId: 'cli-123',
        clienteNombre: 'María Gómez',
        porcentajeParticipacion: 50.0,
      );
      final map = share.toMap();
      final rebuilt = InstrumentClientShare.fromMap(map);

      expect(rebuilt.clienteId, equals('cli-123'));
      expect(rebuilt.clienteNombre, equals('María Gómez'));
      expect(rebuilt.porcentajeParticipacion, equals(50.0));
    });

    test('copyWith preserva valores no alterados y actualiza campos solicitados', () {
      final updated = instrument.copyWith(
        dias: 180,
        retencionPorcentaje: 4.0,
      );

      expect(updated.id, equals('inst-001'));
      expect(updated.numero, equals('CDT-2026-889'));
      expect(updated.entidad, equals('Bancolombia S.A.'));
      expect(updated.dias, equals(180));
      expect(updated.retencionPorcentaje, equals(4.0));
      expect(updated.fechaCierre, equals(apertura.add(const Duration(days: 180))));
      // 300,000 * 0.04 = 12,000
      expect(updated.retencionValor, equals(12000.0));
      // 300,000 - 12,000 = 288,000
      expect(updated.valorFinalRend, equals(288000.0));
    });

    test('Campo estado debe ser Activo por defecto y permitir modificarse con copyWith', () {
      expect(instrument.estado, equals('Activo'));

      final cerrado = instrument.copyWith(estado: 'Cerrado');
      expect(cerrado.estado, equals('Cerrado'));
    });
  });
}
