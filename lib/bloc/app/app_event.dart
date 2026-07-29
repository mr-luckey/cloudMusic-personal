part of 'app_bloc.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

class AppLocaleChanged extends AppEvent {
  final Locale locale;

  const AppLocaleChanged(this.locale);

  @override
  List<Object?> get props => [locale];
}

class AppThemeChanged extends AppEvent {
  const AppThemeChanged();
}
