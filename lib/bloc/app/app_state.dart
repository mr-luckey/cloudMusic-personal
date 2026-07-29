part of 'app_bloc.dart';

class AppState extends Equatable {
  final Locale locale;
  final int themeRevision;

  const AppState({
    required this.locale,
    this.themeRevision = 0,
  });

  AppState copyWith({
    Locale? locale,
    int? themeRevision,
  }) {
    return AppState(
      locale: locale ?? this.locale,
      themeRevision: themeRevision ?? this.themeRevision,
    );
  }

  @override
  List<Object?> get props => [locale, themeRevision];
}
