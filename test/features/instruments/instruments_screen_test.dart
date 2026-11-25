import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart' hide Transaction;
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';
import 'package:koralis_app/features/instruments/domain/repositories/instrument_repository.dart';
import 'package:koralis_app/features/instruments/domain/usecases/get_instruments_usecase.dart';
import 'package:koralis_app/features/instruments/domain/usecases/delete_instrument_usecase.dart';
import 'package:koralis_app/features/instruments/presentation/instruments_screen.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/repositories/transaction_repository.dart';

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
  final List<Instrument> items;
  MockInstrumentRepo(this.items);

  @override
  Future<List<Instrument>> getInstruments() async {
    return List<Instrument>.from(items);
  }

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
  Future<void> deleteInstrument(String id) async {
    items.removeWhere((i) => i.id == id);
  }
}

class _MockTransactionRepo implements TransactionRepository {
  final List<Transaction> txs;
  _MockTransactionRepo(this.txs);

  @override
  Future<List<Transaction>> getTransactions({String? clienteId}) async => txs;

  @override
  Future<void> saveTransaction(Transaction transaction) async {}

  @override
  Future<void> deleteTransaction(String id, {String? clienteId}) async {}
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

  group('InstrumentsScreen - Visualización y tarjetas de instrumentos', () {
    testWidgets('Debe mostrar estado vacío cuando no existen instrumentos', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockInstrumentRepo([]);
      final getInstruments = GetInstrumentsUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: InstrumentsScreen(
            user: testUser,
            getInstrumentsUseCase: getInstruments,
            getProfileUseCase: getProfile,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No hay instrumentos registrados'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Debe renderizar la tarjeta con los 7 campos solicitados', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final apertura = DateTime(2026, 3, 1);
      final inst = Instrument(
        id: 'inst-1',
        numero: 'CDT-9988',
        entidad: 'Davivienda',
        fechaApertura: apertura,
        dias: 60,
        tasaIea: 11.75,
        valorInvertido: 5000000.0,
        rendimientoTProyec: 96000.0,
        retencionPorcentaje: 4.0,
        estado: 'Activo',
      );

      final repo = MockInstrumentRepo([inst]);
      final getInstruments = GetInstrumentsUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: InstrumentsScreen(
            user: testUser,
            getInstrumentsUseCase: getInstruments,
            getProfileUseCase: getProfile,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Entidad (el número ya no forma parte de la tarjeta)
      expect(find.textContaining('Davivienda'), findsOneWidget);
      expect(find.textContaining('CDT-9988'), findsNothing);

      // 2. Fecha Apertura
      expect(find.textContaining('Apertura: 01/03/2026'), findsOneWidget);

      // 3. Fecha Cierre (01/03/2026 + 60 días = 30/04/2026)
      expect(find.textContaining('Cierre: 30/04/2026'), findsOneWidget);

      // 4. % Tasa I.E.A.
      expect(find.text('11.75% I.E.A.'), findsOneWidget);

      // 5. Valor Invertido
      expect(find.textContaining('Invertido: \$ 5.000.000,00'), findsOneWidget);

      // 6. Valor Recibido ($5.000.000 + $96.000 = $5.096.000)
      expect(find.textContaining('Recibido: \$ 5.096.000,00'), findsOneWidget);

      // 7. Valor Final Rend. ($96.000 - $3.840 = $92.160)
      expect(find.text('Valor Final Rend: '), findsOneWidget);
      expect(find.text('\$ 92.160,00'), findsOneWidget);

      // 8. Badge de Estado del Instrumento
      expect(find.text('Activo'), findsOneWidget);
    });

    testWidgets('Tocar una tarjeta abre el modal de detalle rápido', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final inst = Instrument(
        id: 'inst-1',
        numero: 'CDT-9988',
        entidad: 'Davivienda',
        fechaApertura: DateTime(2026, 3, 1),
        dias: 60,
        tasaIea: 11.75,
        valorInvertido: 5000000.0,
        rendimientoTProyec: 96000.0,
        retencionPorcentaje: 4.0,
        estado: 'Activo',
      );

      final repo = MockInstrumentRepo([inst]);
      final getInstruments = GetInstrumentsUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: InstrumentsScreen(
            user: testUser,
            getInstrumentsUseCase: getInstruments,
            getProfileUseCase: getProfile,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tocar la tarjeta
      await tester.tap(find.textContaining('Davivienda'));
      await tester.pumpAndSettle();

      // Verificar que se abrió el bottom sheet de detalle sin botón Editar Instrumento
      expect(find.text('Período de Inversión'), findsOneWidget);
      expect(find.text('Rendimientos Brutos'), findsOneWidget);
      expect(find.text('Activo'), findsWidgets);
      expect(find.text('Editar Instrumento'), findsNothing);
    });

    testWidgets('Al deslizar una tarjeta de instrumento debe mostrar Editar y Eliminar', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final inst = Instrument(
        id: 'inst-1',
        numero: 'CDT-9988',
        entidad: 'Davivienda',
        fechaApertura: DateTime(2026, 3, 1),
        dias: 60,
        tasaIea: 11.75,
        valorInvertido: 5000000.0,
        rendimientoTProyec: 96000.0,
        retencionPorcentaje: 4.0,
        estado: 'Activo',
      );

      final repo = MockInstrumentRepo([inst]);
      final getInstruments = GetInstrumentsUseCase(repo);
      final deleteInstrument = DeleteInstrumentUseCase(
        instrumentRepository: repo,
        transactionRepository: _MockTransactionRepo([]),
      );
      final getProfile = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          routes: {
            '/instrument_form': (context) => const Scaffold(
                  body: Text('Pantalla Formulario Instrumento'),
                ),
          },
          home: InstrumentsScreen(
            user: testUser,
            getInstrumentsUseCase: getInstruments,
            deleteInstrumentUseCase: deleteInstrument,
            getProfileUseCase: getProfile,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.drag(find.byType(AppListCard), const Offset(-180, 0));
      await tester.pumpAndSettle();

      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);

      // Al intentar eliminar un instrumento Activo, debe bloquearse tras confirmar
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      expect(find.text('Eliminar Instrumento'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();
      expect(repo.items.length, equals(1));
      expect(
        find.textContaining('Solo se pueden eliminar instrumentos en estado "Borrador"'),
        findsOneWidget,
      );

      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
      await tester.pumpAndSettle();

      await tester.drag(find.byType(AppListCard), const Offset(-180, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      expect(find.text('Pantalla Formulario Instrumento'), findsOneWidget);
    });

    testWidgets('Al confirmar Eliminar en instrumento Borrador sin transacciones debe eliminarlo', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final instBorrador = Instrument(
        id: 'inst-borrador',
        numero: 'CDT-DRAFT',
        entidad: 'Bancolombia',
        fechaApertura: DateTime(2026, 3, 1),
        dias: 30,
        tasaIea: 10.0,
        valorInvertido: 1000000.0,
        rendimientoTProyec: 8000.0,
        estado: 'Borrador',
      );

      final repo = MockInstrumentRepo([instBorrador]);
      final deleteInstrument = DeleteInstrumentUseCase(
        instrumentRepository: repo,
        transactionRepository: _MockTransactionRepo([]),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: InstrumentsScreen(
            user: testUser,
            getInstrumentsUseCase: GetInstrumentsUseCase(repo),
            deleteInstrumentUseCase: deleteInstrument,
            getProfileUseCase: GetProfileUseCase(MockProfileRepo()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.drag(find.byType(AppListCard), const Offset(-180, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(repo.items, isEmpty);
      expect(find.text('No hay instrumentos registrados'), findsOneWidget);
    });

    testWidgets('Debe mostrar badge Borrador cuando el instrumento tiene estado Borrador', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final inst = Instrument(
        id: 'inst-borrador',
        numero: 'CDT-DRAFT',
        entidad: 'Bancolombia',
        fechaApertura: DateTime(2026, 3, 1),
        dias: 30,
        tasaIea: 10.0,
        valorInvertido: 1000000.0,
        rendimientoTProyec: 8000.0,
        estado: 'Borrador',
      );

      final repo = MockInstrumentRepo([inst]);
      final getInstruments = GetInstrumentsUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: InstrumentsScreen(
            user: testUser,
            getInstrumentsUseCase: getInstruments,
            getProfileUseCase: getProfile,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Borrador'), findsOneWidget);
    });
  });
}
