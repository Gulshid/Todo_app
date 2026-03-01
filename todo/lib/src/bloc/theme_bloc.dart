import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ThemeEvent {}
class ToggleTheme extends ThemeEvent {}

class ThemeState {
  final ThemeMode themeMode;
  const ThemeState(this.themeMode);
  bool get isDark => themeMode == ThemeMode.dark;
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState(ThemeMode.system)) {
    on<ToggleTheme>((event, emit) {
      emit(ThemeState(
        state.isDark ? ThemeMode.light : ThemeMode.dark,
      ));
    });
  }
}