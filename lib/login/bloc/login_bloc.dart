import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final ApiService apiService;

  LoginBloc({required this.apiService}) : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      final result = await apiService.login(event.username, event.password);

      if (result['status'] == true) {
        final String? token = result['jwt'];

        if (token != null && token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_token', token);

          emit(LoginSuccess());
        } else {
          emit(LoginFailure(error: 'Login berhasil, namun token tidak diterima.'));
        }
      } else {
        final String errorMessage = result['message'] ?? result['error'] ?? 'Username atau password salah!';
        emit(LoginFailure(error: errorMessage));
      }
    } catch (e) {
      String errorMsg = e.toString();

      // Hapus prefix Exception:  agar pesan error lebih bersih 
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring('Exception: '.length);
      }

      emit(LoginFailure(error: errorMsg));
    }
  }
}