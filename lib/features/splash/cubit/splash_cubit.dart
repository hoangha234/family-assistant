import 'package:flutter_bloc/flutter_bloc.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(const SplashState());

  Future<void> checkAuthStatus() async {
    emit(state.copyWith(status: SplashStatus.loading));
    
    // TODO: Add actual authentication check logic here.
    // Replace the mock delay with actual auth verification.
    await Future.delayed(const Duration(seconds: 2));
    
    // Mocking an unauthenticated state for now
    emit(state.copyWith(status: SplashStatus.unauthenticated));
  }
}
