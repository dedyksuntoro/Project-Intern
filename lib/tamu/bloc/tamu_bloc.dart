import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/api_service.dart';
part 'tamu_event.dart';
part 'tamu_state.dart';

class TamuBloc extends Bloc<TamuEvent, TamuState> {
  final ApiService _apiService = ApiService();

  TamuBloc() : super(TamuInitial()) {
    on<TamuFormSubmitted>(_onTamuFormSubmitted);
  }

  Future<void> _onTamuFormSubmitted(
    TamuFormSubmitted event,
    Emitter<TamuState> emit,
  ) async {
    emit(TamuSubmissionInProgress());

    try {
      //proses upload ke server
      await _apiService.submitTamu(
        nama: event.nama,
        instansi: event.instansi,
        menemui: event.menemui,
        keperluan: event.keperluan,
        foto: event.foto,
      );
      
      //keluarkan state success
      emit(TamuSubmissionSuccess());

      
      for (var file in event.foto) {
        if (await file.exists()) {
          try {
            await file.delete();
            print('File temporer tamu berhasil dihapus: ${file.path}');
          } catch (e) {
            // Gagal menghapus, cukup catat log-nya
            print('Gagal menghapus file temporer tamu: $e');
          }
        }
      }
   

    } catch (e) {
      // Jika terjadi error, file tidak akan dihapus, sehingga pengguna bisa mencoba lagi
      emit(TamuSubmissionFailure(error: e.toString().replaceAll('Exception: ', '')));
    }
  }
}