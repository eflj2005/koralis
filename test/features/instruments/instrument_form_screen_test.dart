import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart' hide Transaction;
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
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/repositories/client_repository.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:koralis_app/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:koralis_app/features/transactions/domain/usecases/save_transaction_usecase.dart';

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
    final instrumentConId = instrument.id.trim().isNotEmpty
        ? instrument
        : instrument.copyWith(id: 'mock_inst_${items.length + 1}');
    final idx = items.indexWhere((i) => i.id == instrumentConId.id);
    if (idx >= 0) {
      items[idx] = instrumentConId;
    } else {
      items.add(instrumentConId);
    }
  }

  @override
  Future<void> deleteInstrument(String id) async => items.removeWhere((i) => i.id == id);
}

class MockClientRepo implements ClientRepository {
  final List<Client> clientes;

  MockClientRepo({List<Client>? clientes})
      : clientes = clientes != null ? List.from(clientes) : [];

  @override
  Future<List<Client>> getClients() async => clientes;

  @override
  Future<void> addClient(Client client) async => clientes.add(client);
}

class MockTransactionRepo implements TransactionRepository {
  final List<Transaction> transacciones;

  MockTransactionRepo({List<Transaction>? transacciones})
      : transacciones = transacciones != null ? List.from(transacciones) : [];

  @override
  Future<List<Transaction>> getTransactions({String? clienteId}) async => transacciones;

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final txConId = transaction.id.trim().isNotEmpty
        ? transaction
        : transaction.copyWith(id: 'mock_tx_${transacciones.length + 1}');
    final idx = transacciones.indexWhere((t) => t.id == txConId.id);
    if (idx >= 0) {
      transacciones[idx] = txConId;
    } else {
      transacciones.add(txConId);
    }
  }

  @override
  Future<void> deleteTransaction(String id, {String? clienteId}) async =>
      transacciones.removeWhere((t) => t.id == id);
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
      expect(find.text('Estado Operativo'), findsOneWidget);
      expect(find.text('Observación'), findsOneWidget);
      expect(find.text('Registrar Instrumento'), findsOneWidget);

      // Verificar navegación a Tab 2: Aportes
      await tester.tap(find.text('Aportes'));
      await tester.pumpAndSettle();
      expect(find.text('Aportes de Clientes (Inversión)'), findsOneWidget);

      // Verificar navegación a Tab 3: Resultados (Resumen Financiero)
      await tester.tap(find.text('Resultados'));
      await tester.pumpAndSettle();
      expect(find.text('Resumen Financiero Calculado'), findsOneWidget);
      expect(find.text('Retención (4.00%):'), findsOneWidget);
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

      final estadoFinder = find.text('Estado Operativo');
      expect(estadoFinder, findsOneWidget);

      await tester.ensureVisible(estadoFinder);
      await tester.pumpAndSettle();

      expect(find.text('Borrador'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget);
      expect(find.text('Cerrado'), findsOneWidget);

      // Tocar el botón interactivo de 'Activo'
      await tester.tap(find.text('Activo'));
      await tester.pumpAndSettle();

      // Tocar el botón interactivo de 'Cerrado'
      await tester.tap(find.text('Cerrado'));
      await tester.pumpAndSettle();

      expect(find.text('Cerrado'), findsOneWidget);
    });

    testWidgets('En modo edición, el Tab Resultados debe reflejar el Resumen Financiero y la lista de Clientes con transacciones de Inversión', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final existente = Instrument(
        id: 'inst-777',
        numero: 'CDT-COLP-101',
        entidad: 'Davivienda',
        fechaApertura: DateTime(2026, 3, 1),
        dias: 180,
        tasaIea: 10.0,
        valorInvertido: 50000000,
        rendimientoTProyec: 2500000,
        retencionPorcentaje: 4.0,
        observacion: 'Prueba de clientes asociados',
      );

      final transaccionesMock = [
        Transaction(
          id: 'tx-001',
          clienteId: 'cli-001',
          clienteNombre: 'Carlos Santana',
          tipo: TransactionType.inversion,
          valor: 30000000,
          fecha: DateTime(2026, 3, 2),
          instrumentoId: 'inst-777',
        ),
        Transaction(
          id: 'tx-002',
          clienteId: 'cli-002',
          clienteNombre: 'Mariana Pajón',
          tipo: TransactionType.inversion,
          valor: 20000000,
          fecha: DateTime(2026, 3, 5),
          instrumentoId: 'inst-777',
        ),
        // Transacción que no es de inversión o de otro instrumento (no debe listarse)
        Transaction(
          id: 'tx-003',
          clienteId: 'cli-003',
          clienteNombre: 'Cliente Ajeno',
          tipo: TransactionType.retiro,
          valor: 5000000,
          fecha: DateTime(2026, 3, 10),
          instrumentoId: 'inst-999',
        ),
      ];

      final repo = MockInstrumentRepo();
      final saveUseCase = SaveInstrumentUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());
      final getBanks = GetBanksUseCase(MockBankRepo());
      final getTransactions = GetTransactionsUseCase(
        MockTransactionRepo(transacciones: transaccionesMock),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: InstrumentFormScreen(
            user: testUser,
            instrument: existente,
            saveInstrumentUseCase: saveUseCase,
            getProfileUseCase: getProfile,
            getBanksUseCase: getBanks,
            getTransactionsUseCase: getTransactions,
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Verificar que estamos en Tab 1 con Retención editable
      expect(find.text('Retención %'), findsOneWidget);

      // Cambiar a Tab 2: Aportes
      await tester.tap(find.text('Aportes'));
      await tester.pumpAndSettle();

      // Verificar que aparezcan los clientes asociados con sus transacciones de tipo inversión
      expect(find.text('Aportes de Clientes (Inversión)'), findsOneWidget);
      expect(find.text('Total Aportado (2):'), findsOneWidget);
      expect(find.text('Carlos Santana'), findsOneWidget);
      expect(find.text('Mariana Pajón'), findsOneWidget);
      expect(find.text('Cliente Ajeno'), findsNothing);

      // Cambiar a Tab 3: Resultados
      await tester.tap(find.text('Resultados'));
      await tester.pumpAndSettle();

      // Verificar Resumen Financiero Calculado
      expect(find.text('Resumen Financiero Calculado'), findsOneWidget);
      expect(find.text('Retención (4.00%):'), findsOneWidget);

      // Regresar a Tab 1, cambiar la retención a 7.00% y verificar actualización reactiva en Tab 3
      await tester.tap(find.text('Generalidades'));
      await tester.pumpAndSettle();

      final retencionField = find.widgetWithText(AppTextField, 'Retención %');
      await tester.enterText(retencionField, '7.00');
      await tester.pumpAndSettle();

      // Volver a Tab 3 y verificar el cambio reactivo
      await tester.tap(find.text('Resultados'));
      await tester.pumpAndSettle();

      expect(find.text('Retención (7.00%):'), findsOneWidget);
    });

    testWidgets('En Tab 2 Aportes, debe abrir el modal para agregar aportes, mostrar disponible y validar monto', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cliente1 = Client(
        id: 'cli-001',
        nombre: 'Carlos Santana',
        documento: '10203040',
        correo: 'carlos@example.com',
        telefono: '3001234567',
        transacciones: [
          Transaction(
            id: 'tx-recarga-1',
            clienteId: 'cli-001',
            clienteNombre: 'Carlos Santana',
            tipo: TransactionType.recarga,
            valor: 15000000,
            fecha: DateTime(2026, 1, 10),
          ),
        ],
      );

      final clienteInactivo = Client(
        id: 'cli-inactivo',
        nombre: 'Cliente Desactivado',
        documento: '99999999',
        correo: 'inactivo@example.com',
        telefono: '3000000000',
        estado: 'Inactivo',
      );

      final existente = Instrument(
        id: 'inst-777',
        numero: 'CDT-2026-001',
        entidad: 'Bancolombia',
        fechaApertura: DateTime(2026, 3, 1),
        dias: 90,
        tasaIea: 12.50,
        valorInvertido: 50000000,
        rendimientoTProyec: 1500000,
        retencionPorcentaje: 4.00,
        observacion: 'Instrumento inicial',
        estado: 'Activo',
        fechaCreacion: DateTime(2026, 3, 1),
      );

      final repoInst = MockInstrumentRepo();
      final saveUseCase = SaveInstrumentUseCase(repoInst);
      final getProfile = GetProfileUseCase(MockProfileRepo());
      final getBanks = GetBanksUseCase(MockBankRepo());
      final txRepo = MockTransactionRepo(transacciones: []);
      final getTransactions = GetTransactionsUseCase(txRepo);
      final saveTransaction = SaveTransactionUseCase(txRepo);
      final getClients = GetClientsUseCase(
        MockClientRepo(clientes: [cliente1, clienteInactivo]),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: InstrumentFormScreen(
            user: testUser,
            instrument: existente,
            saveInstrumentUseCase: saveUseCase,
            getProfileUseCase: getProfile,
            getBanksUseCase: getBanks,
            getTransactionsUseCase: getTransactions,
            getClientsUseCase: getClients,
            saveTransactionUseCase: saveTransaction,
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Navegar a Tab 2: Aportes
      await tester.tap(find.text('Aportes'));
      await tester.pumpAndSettle();

      // Inicialmente no hay aportes, se muestra el estado vacío y el botón
      expect(find.text('No hay transacciones de inversión vinculadas a este instrumento todavía.'), findsOneWidget);
      expect(find.text('Agregar Aporte'), findsOneWidget);

      // Abrir modal de nuevo aporte
      await tester.tap(find.text('Agregar Aporte'));
      await tester.pumpAndSettle();

      // Verificar que el modal se muestre
      expect(find.text('Nuevo Aporte de Inversión'), findsOneWidget);
      expect(find.text('Instrumento: CDT-2026-001'), findsOneWidget);

      // Seleccionar cliente desde el dropdown
      await tester.tap(find.text('Selecciona el cliente...'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Debe aparecer el cliente activo pero NO el inactivo
      expect(find.text('Carlos Santana - 10203040').last, findsOneWidget);
      expect(find.text('Cliente Desactivado - 99999999'), findsNothing);

      await tester.tap(find.text('Carlos Santana - 10203040').last);
      await tester.pumpAndSettle();

      // Al seleccionar el cliente se debe consultar y mostrar su disponible informativo
      expect(find.text('Saldo Disponible del Cliente'), findsOneWidget);
      expect(find.text('\$ 15.000.000,00'), findsOneWidget);

      // Probar validación: monto que supera el disponible ($ 20.000.000 > $ 15.000.000)
      final valorAporteField = find.widgetWithText(AppTextField, 'Valor a Invertir (\$)');
      await tester.enterText(valorAporteField, '20000000');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Registrar Aporte'));
      await tester.pumpAndSettle();

      expect(find.text('Supera el disponible (\$ 15.000.000,00)'), findsOneWidget);

      // Ingresar un monto válido dentro del disponible ($ 5.000.000)
      await tester.enterText(valorAporteField, '5000000');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Registrar Aporte'));
      await tester.pumpAndSettle();

      // El modal debe haberse cerrado
      expect(find.text('Nuevo Aporte de Inversión'), findsNothing);

      // En Tab 2 ahora debe listarse la nueva inversión (aparece en el total y en la tarjeta individual)
      expect(find.text('Total Aportado (1):'), findsOneWidget);
      expect(find.text('Carlos Santana'), findsOneWidget);
      expect(find.text('\$ 5.000.000,00'), findsNWidgets(2));
    });
  });
}
