part of 'tugas_ob_bloc.dart';

enum TugasObStatus { initial, loading, success, failure, submitting }

class TugasObState extends Equatable {
  final TugasObStatus status;
  
  // List Data Master
  final List<Cabang> daftarCabang;
  final List<ObArea> daftarArea;     
  final List<ObTugas> daftarTugas;   
  final List<Karyawan> daftarKaryawan;

  // Item Terpilih
  final Cabang? selectedCabang;
  final ObArea? selectedArea;        
  final ObTugas? selectedTugas;     
  final Karyawan? selectedKaryawan;

  final String? errorMessage;

  const TugasObState({
    this.status = TugasObStatus.initial,
    this.daftarCabang = const [],
    this.daftarArea = const [],
    this.daftarTugas = const [],
    this.daftarKaryawan = const [],
    this.selectedCabang,
    this.selectedArea,
    this.selectedTugas,
    this.selectedKaryawan,
    this.errorMessage,
  });

  TugasObState copyWith({
    TugasObStatus? status,
    List<Cabang>? daftarCabang,
    List<ObArea>? daftarArea,
    List<ObTugas>? daftarTugas,
    List<Karyawan>? daftarKaryawan,
    Cabang? selectedCabang,
    ObArea? selectedArea,
    ObTugas? selectedTugas,
    Karyawan? selectedKaryawan,
    String? errorMessage,
  }) {
    return TugasObState(
      status: status ?? this.status,
      daftarCabang: daftarCabang ?? this.daftarCabang,
      daftarArea: daftarArea ?? this.daftarArea,
      daftarTugas: daftarTugas ?? this.daftarTugas,
      daftarKaryawan: daftarKaryawan ?? this.daftarKaryawan,
      selectedCabang: selectedCabang ?? this.selectedCabang,
      selectedArea: selectedArea ?? this.selectedArea,
      selectedTugas: selectedTugas ?? this.selectedTugas,
      selectedKaryawan: selectedKaryawan ?? this.selectedKaryawan,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        daftarCabang,
        daftarArea,
        daftarTugas,
        daftarKaryawan,
        selectedCabang,
        selectedArea,
        selectedTugas,
        selectedKaryawan,
        errorMessage,
      ];
}