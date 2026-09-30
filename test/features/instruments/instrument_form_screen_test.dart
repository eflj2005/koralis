import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';
import 'package:koralis_app/features/instruments/domain/repositories/instrument_repository.dart';
import 'package:koralis_app/features/instruments/domain/usecases/save_instrument_usecase.dart';
import 'package:koralis_app/features/instruments/presentation/instrument_form_screen.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';

class MockProfileRepo implements ProfileRepository {
  @override
  Future<Profile> getProfile(String userId) async {
    return Profile(
      id: 'p1',
      userId: userId,
      avatarPath: '',
      nombre: 'Edwin Londoño',
      correo: 'edwin@koralis.com',
    );
  }
}

class MockInstrumentRepo implements InstrumentRepository {
  final List<Instrument> items = [];

  @override
  Future<List<Instrument>> getInstruments() async => items;

  @override
  Future<void> saveInstrument(Instrument instrument) async {
    final idx = items.indexWhere((i) => i.id == instrument.id);
    if (idx >= 0) {
      items[idx] = instrument;
    } else {
      items.add(instrument);
    }
  }

  @override
  Future<void> deleteInstrument(String id) async => items.removeWhere((i) => i.id == id);
}

void main() {
  final testTheme = ThemeData.dark().copyWith(
    splashFactory: InkRipple.splashFactory,
  );

  final testUser = User(
    id: 'user-001',
    nombre: 'Edwin Londoño',
    correo: 'edwin@koralis.com',
  );

  group('InstrumentFormScreen - Formulario Reactivo y Cálculos Dinámicos', () {
    testWidgets('Debe renderizar los campos de entrada y el resumen financiero inicial', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockInstrumentRepo();
      final saveUseCase = SaveInstrumentUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: InstrumentFormScreen(
            user: testUser,
            saveInstrumentUseCase: saveUseCase,
            getProfileUseCase: getProfile,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Nuevo Instrumento'), findsOneWidget);
      expect(find.text('Número de Instrumento / Folio'), findsOneWidget);
      expect(find.text('Entidad Financiera'), findsOneWidget);
      expect(find.text('Fecha Apertura'), findsOneWidget);
      expect(find.text('Plazo (Días)'), findsOneWidget);
      expect(find.text('% Tasa I.E.A.'), findsOneWidget);
      expect(find.text('Valor Invertido (\$)'), findsOneWidget);
      expect(find.text('Rendimiento T. Proyec. (\$)'), findsOneWidget);
      expect(find.text('Retención %'), findsOneWidget);
      expect(find.text('Retención (\$):'), findsOneWidget);
      expect(find.text('Observación'), findsOneWidget);

      // Resumen Financiero Dinámico
      expect(find.text('Resumen Financiero Calculado'), findsOneWidget);
      expect(find.text('Registrar Instrumento'), findsOneWidget);
    });

    testWidgets('Cargar en modo edición debe precargar los valores del instrumento', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final existente = Instrument(
        id: 'inst-999',
        numero: 'CDT-BCOL-5544',
        entidad: 'Bancolombia',
        fechaApertura: DateTime(2026, 2, 10),
        dias: 90,
        tasaIea: 12.35,
        valorInvertido: 25000000,
        rendimientoTProyec: 750000,
        retencionPorcentaje: 7.0,
        observacion: 'Tasa promocional',
      );

      final repo = MockInstrumentRepo();
      final saveUseCase = SaveInstrumentUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: InstrumentFormScreen(
            user: testUser,
            instrument: existente,
            saveInstrumentUseCase: saveUseCase,
            getProfileUseCase: getProfile,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Editar Instrumento'), findsOneWidget);
      expect(find.text('CDT-BCOL-5544'), findsOneWidget);
      expect(find.text('Bancolombia'), findsOneWidget);
      expect(find.text('Guardar Cambios'), findsOneWidget);
    });
  });
}
