import 'package:flutter/foundation.dart';
import 'package:koralis_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';

/// ViewModel global encargado de gestionar el perfil del usuario autenticado.
///
/// Mantiene en caché el perfil cargado por `userId` para evitar consultas repetidas
/// entre pantallas y expone un estado limpio para la capa de presentación.
class ProfileViewModel extends ChangeNotifier {
  GetProfileUseCase? _getProfileUseCase;

  Profile? _profile;
  String? _loadedUserId;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  ProfileViewModel({GetProfileUseCase? getProfileUseCase})
      : _getProfileUseCase = getProfileUseCase;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  GetProfileUseCase _obtenerUseCase() =>
      _getProfileUseCase ??= GetProfileUseCase(ProfileRepositoryImpl());

  void _notificar() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Carga el perfil del usuario indicado, reutilizando caché salvo que [forzar] sea true.
  Future<void> cargarPerfil(String userId, {bool forzar = false}) async {
    final uid = userId.trim();
    if (uid.isEmpty) return;
    if (!forzar && _profile != null && _loadedUserId == uid) return;

    _isLoading = true;
    _errorMessage = null;
    _notificar();

    try {
      final resultado = await _obtenerUseCase().execute(uid);
      _profile = resultado;
      _loadedUserId = uid;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _notificar();
    }
  }

  /// Limpia el estado almacenado (por ejemplo, al cerrar sesión).
  void limpiar() {
    _profile = null;
    _loadedUserId = null;
    _errorMessage = null;
    _isLoading = false;
    _notificar();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
