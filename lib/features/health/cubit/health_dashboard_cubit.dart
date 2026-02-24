import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'health_dashboard_state.dart';

class HealthDashboardCubit extends Cubit<HealthDashboardState> {
  HealthDashboardCubit() : super(HealthDashboardInitial());
}
