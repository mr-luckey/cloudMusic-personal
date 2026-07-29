part of 'theme_settings_bloc.dart';

class ThemeSettingsState extends Equatable {
  final String canvasColor;
  final String cardColor;
  final String theme;
  final Map userThemes;
  final String themeColor;
  final int colorHue;
  final int refreshTick;

  const ThemeSettingsState({
    required this.canvasColor,
    required this.cardColor,
    required this.theme,
    required this.userThemes,
    required this.themeColor,
    required this.colorHue,
    this.refreshTick = 0,
  });

  factory ThemeSettingsState.initial() {
    final box = Hive.box('settings');
    return ThemeSettingsState(
      canvasColor: box.get('canvasColor', defaultValue: 'Grey') as String,
      cardColor: box.get('cardColor', defaultValue: 'Grey900') as String,
      theme: box.get('theme', defaultValue: 'Default') as String,
      userThemes: box.get('userThemes', defaultValue: {}) as Map,
      themeColor: box.get('themeColor', defaultValue: 'Teal') as String,
      colorHue: box.get('colorHue', defaultValue: 400) as int,
    );
  }

  ThemeSettingsState copyWith({
    String? canvasColor,
    String? cardColor,
    String? theme,
    Map? userThemes,
    String? themeColor,
    int? colorHue,
    int? refreshTick,
  }) {
    return ThemeSettingsState(
      canvasColor: canvasColor ?? this.canvasColor,
      cardColor: cardColor ?? this.cardColor,
      theme: theme ?? this.theme,
      userThemes: userThemes ?? this.userThemes,
      themeColor: themeColor ?? this.themeColor,
      colorHue: colorHue ?? this.colorHue,
      refreshTick: refreshTick ?? this.refreshTick,
    );
  }

  @override
  List<Object?> get props => [
        canvasColor,
        cardColor,
        theme,
        userThemes,
        themeColor,
        colorHue,
        refreshTick,
      ];
}
