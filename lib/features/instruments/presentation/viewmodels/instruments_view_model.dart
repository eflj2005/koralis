import 'package:flutter/foundation.dart';
import 'package:koralis_app/features/instruments/data/repositories/instrument_repository_impl.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';
import 'package:koralis_app/features/instruments/domain/usecases/delete_instrument_usecase.dart';
import 'package:koralis_app/features/instruments/domain/usecases/get_instruments_usecase.dart';
import 'package:koralis_app/features/transactions/data/repositories/transaction_repository_impl.dart';

/// ViewModel de la pantalla principal de Instrumentos Financieros.
class InstrumentsViewModel extends ChangeNotifier {
  final String _userId;
  GetInstrumentsUseCase? _getInstrumentsUseCase;
  DeleteInstrumentUseCase? _deleteInstrumentUseCase;

  List<Instrument> _instrumentos = const [];
  bool _isLoading = false;
  bool _eliminando = false;
  String? _errorMessage;
  bool _disposed = false;

  InstrumentsViewModel({
    required String userId,
    GetInstrumentsUseCase? getInstrumentsUseCase,
    DeleteInstrumentUseCase? deleteInstrumentUseCase,
  })  : _userId = userId,
        _getInstrumentsUseCase = getInstrumentsUseCase,
        _deleteInstrumentUseCase = deleteInstrumentUseCase;

  List<Instrument> get instrumentos => List.unmodifiable(_instrumentos);
  bool get isLoading => _isLoading;
  bool get eliminando => _eliminando;
  String? get errorMessage => _errorMessage;

  GetInstrumentsUseCase _obtenerGetInstrumentsUseCase() =>
      _getInstrumentsUseCase ??= GetInstrumentsUseCase(
        InstrumentRepositoryImpl(userId: _userId),
      );

  DeleteInstrumentUseCase _obtenerDeleteInstrumentUseCase() =>
      _deleteInstrumentUseCase ??= DeleteInstrumentUseCase(
        instrumentRepository: InstrumentRepositoryImpl(userId: _userId),
        transactionRepository: TransactionRepositoryImpl(userId: _userId),
      );

  void _notificar() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Consulta y actualiza el listado de instrumentos del usuario.
  Future<void> cargarInstrumentos() async {
    _isLoading = true;
    _errorMessage = null;
    _notificar();

    try {
      _instrumentos = await _obtenerGetInstrumentsUseCase().execute();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _notificar();
    }
  }

  /// Elimina un instrumento validando su estado y registros asociados, y recarga la lista.
  Future<void> eliminarInstrumento(Instrument instrumento) async {
    _eliminando = true;
    _notificar();

    try {
      await _obtenerDeleteInstrumentUseCase().execute(instrumento);
      await cargarInstrumentos();
    } finally {
      _eliminando = false;
      _notificar();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
