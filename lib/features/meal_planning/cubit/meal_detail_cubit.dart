import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'meal_detail_state.dart';

class MealDetailCubit extends Cubit<MealDetailState> {
  MealDetailCubit() : super(const MealDetailState());

  void setTab(bool isIngredients) {
    emit(state.copyWith(isIngredientsTab: isIngredients));
  }
}
