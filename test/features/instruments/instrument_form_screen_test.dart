import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';
import 'package:koralis_app/features/instruments/domain/repositories/instrument_repository.dart';
import 'package:koralis_app/features/instruments/domain/usecases/save_instrument_usecase.dart';
import 'package:koralis_app/features/instruments/presentation/instrument_form_screen.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:koralis_app/features/instruments/domain/entities/bank.dart';
import 'package:koralis_app/features/instruments/domain/repositories/bank_repository.dart';
import 'package:koralis_app/features/instruments/domain/usecases/get_banks_usecase.dart';

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

class MockBankRepo implements BankRepository {
  final List<Bank> bancos;

  MockBankRepo({
    this.bancos = const [
      Bank(id: 'b1', nombre: 'Bancolombia'),
      Bank(id: 'b2', nombre: 'Davivienda'),
      Bank(id: 'b3', nombre: 'Skandia'),
    ],
  });

  @override
  Future<List<Bank>> getBanks() async => bancos;
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
      final getBanks = GetBanksUseCase(MockBankRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: InstrumentFormScreen(
            user: testUser,
            saveInstrumentUseCase: saveUseCase,
            getProfileUseCase: getProfile,
            getBanksUseCase: getBanks,
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
      expect(find.text('Estado del Instrumento'), findsOneWidget);
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
      final getBanks = GetBanksUseCase(MockBankRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: InstrumentFormScreen(
            user: testUser,
            instrument: existente,
            saveInstrumentUseCase: saveUseCase,
            getProfileUseCase: getProfile,
            getBanksUseCase: getBanks,
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

    testWidgets('Debe permitir seleccionar una entidad financiera desde la lista desplegable de banks', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockInstrumentRepo();
      final saveUseCase = SaveInstrumentUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());
      final getBanks = GetBanksUseCase(MockBankRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: InstrumentFormScreen(
            user: testUser,
            saveInstrumentUseCase: saveUseCase,
            getProfileUseCase: getProfile,
            getBanksUseCase: getBanks,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Abrir lista desplegable de Entidad Financiera
      await tester.tap(find.widgetWithText(AppDropdownField<String>, 'Entidad Financiera'));
      await tester.pumpAndSettle();

      // Verificar que aparezcan las opciones de bancos
      expect(find.text('Davivienda').last, findsOneWidget);

      // Seleccionar Davivienda
      await tester.tap(find.text('Davivienda').last);
      await tester.pumpAndSettle();

      expect(find.text('Davivienda'), findsOneWidget);
    });

    testWidgets('El campo Plazo (Días) no debe permitir más de 3 dígitos', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockInstrumentRepo();
      final saveUseCase = SaveInstrumentUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());
      final getBanks = GetBanksUseCase(MockBankRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: InstrumentFormScreen(
            user: testUser,
            saveInstrumentUseCase: saveUseCase,
            getProfileUseCase: getProfile,
            getBanksUseCase: getBanks,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final plazoFinder = find.widgetWithText(AppTextField, 'Plazo (Días)');
      expect(plazoFinder, findsOneWidget);

      // Ingresar 4 dígitos
      await tester.enterText(plazoFinder, '1234');
      await tester.pump();

      // Debe limitarse automáticamente a 3 dígitos (123)
      final textField = tester.widget<TextField>(
        find.descendant(of: plazoFinder, matching: find.byType(TextField)),
      );
      expect(textField.controller?.text, '123');
    });

    testWidgets('Debe permitir seleccionar el Estado del instrumento (Activo / Cerrado)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockInstrumentRepo();
      final saveUseCase = SaveInstrumentUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());
      final getBanks = GetBanksUseCase(MockBankRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: InstrumentFormScreen(
            user: testUser,
            saveInstrumentUseCase: saveUseCase,
            getProfileUseCase: getProfile,
            getBanksUseCase: getBanks,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final estadoFinder = find.widgetWithText(AppDropdownField<String>, 'Estado del Instrumento');
      expect(estadoFinder, findsOneWidget);

      await tester.ensureVisible(estadoFinder);
      await tester.pumpAndSettle();

      await tester.tap(estadoFinder);
      await tester.pumpAndSettle();

      expect(find.text('Cerrado').last, findsOneWidget);
      await tester.tap(find.text('Cerrado').last);
      await tester.pumpAndSettle();

      expect(find.text('Cerrado'), findsOneWidget);
    });
  });
}
