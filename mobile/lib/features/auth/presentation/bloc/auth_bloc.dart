import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/login_use_case.dart';
import '../../domain/use_cases/logout_use_case.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final AuthRepository _repo;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required AuthRepository repo,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _repo = repo,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<LoginRequested>(_onLogin);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onCheck(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final usuario = await _repo.getCachedUsuario();
    if (usuario != null) {
      emit(AuthAuthenticated(usuario));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _loginUseCase(
      empresa: event.empresa,
      usuario: event.usuario,
      clave: event.clave,
      captchaA: event.captchaA,
      captchaB: event.captchaB,
      captchaAnswer: event.captchaAnswer,
    );
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (usuario) => emit(AuthAuthenticated(usuario)),
    );
  }

  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _logoutUseCase(event.refreshToken);
    emit(const AuthUnauthenticated());
  }
}
