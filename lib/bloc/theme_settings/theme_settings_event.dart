part of 'theme_settings_bloc.dart';

abstract class ThemeSettingsEvent extends Equatable {
  const ThemeSettingsEvent();

  @override
  List<Object?> get props => [];
}

class ThemeAccentColorUpdated extends ThemeSettingsEvent {
  final String themeColor;
  final int colorHue;

  const ThemeAccentColorUpdated({
    required this.themeColor,
    required this.colorHue,
  });

  @override
  List<Object?> get props => [themeColor, colorHue];
}

class ThemeCanvasColorUpdated extends ThemeSettingsEvent {
  final String canvasColor;

  const ThemeCanvasColorUpdated(this.canvasColor);

  @override
  List<Object?> get props => [canvasColor];
}

class ThemeCardColorUpdated extends ThemeSettingsEvent {
  final String cardColor;

  const ThemeCardColorUpdated(this.cardColor);

  @override
  List<Object?> get props => [cardColor];
}

class ThemeSwitchToCustom extends ThemeSettingsEvent {
  const ThemeSwitchToCustom();
}

class ThemeSelectionUpdated extends ThemeSettingsEvent {
  final String theme;
  final String canvasColor;
  final String cardColor;
  final String themeColor;
  final int colorHue;

  const ThemeSelectionUpdated({
    required this.theme,
    required this.canvasColor,
    required this.cardColor,
    required this.themeColor,
    required this.colorHue,
  });

  @override
  List<Object?> get props =>
      [theme, canvasColor, cardColor, themeColor, colorHue];
}

class ThemeDeleted extends ThemeSettingsEvent {
  final Map userThemes;
  final String theme;

  const ThemeDeleted({
    required this.userThemes,
    required this.theme,
  });

  @override
  List<Object?> get props => [userThemes, theme];
}

class ThemeSaved extends ThemeSettingsEvent {
  final Map userThemes;
  final String theme;

  const ThemeSaved({
    required this.userThemes,
    required this.theme,
  });

  @override
  List<Object?> get props => [userThemes, theme];
}

class ThemeUiRefreshed extends ThemeSettingsEvent {
  const ThemeUiRefreshed();
}

class ThemeAmoledApplied extends ThemeSettingsEvent {
  final String canvasColor;
  final String cardColor;
  final String themeColor;
  final int colorHue;

  const ThemeAmoledApplied({
    required this.canvasColor,
    required this.cardColor,
    required this.themeColor,
    required this.colorHue,
  });

  @override
  List<Object?> get props => [canvasColor, cardColor, themeColor, colorHue];
}
