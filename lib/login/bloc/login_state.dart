part of 'login_bloc.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];
}

// State awal sebelum ada interaksi
class LoginInitial extends LoginState {}

// State saat sedang loading (menghubungi API)
class LoginLoading extends LoginState {}

// State saat login berhasil
class LoginSuccess extends LoginState {}

// State saat login gagal
class LoginFailure extends LoginState {
  final String error;

  const LoginFailure({required this.error});

  @override
  List<Object> get props => [error];
}
