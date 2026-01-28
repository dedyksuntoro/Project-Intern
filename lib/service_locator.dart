
import 'package:get_it/get_it.dart';
import 'services/api_service.dart';

final GetIt locator = GetIt.instance;


Future<void> setupLocator() async {
  locator.registerLazySingleton(() => ApiService());

 
  await locator<ApiService>().init();
}