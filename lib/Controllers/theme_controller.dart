import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// GetX Controller for Theme Settings
class ThemeController extends GetxController {
  final RxString currentTheme = 'Default'.obs;
  final RxBool isDarkMode = true.obs;
  final RxInt accentColor = 0.obs;
  final RxBool useSystemTheme = false.obs;
  final RxString gradientType = 'halfDark'.obs;

  @override
  void onInit() {
    super.onInit();
    loadThemeSettings();
  }

  void loadThemeSettings() {
    final settingsBox = Hive.box('settings');
    currentTheme.value =
        settingsBox.get('theme', defaultValue: 'Default').toString();
    isDarkMode.value = settingsBox.get('darkMode', defaultValue: true) as bool;
    accentColor.value = settingsBox.get('accentColor', defaultValue: 0) as int;
    useSystemTheme.value =
        settingsBox.get('useSystemTheme', defaultValue: false) as bool;
    gradientType.value =
        settingsBox.get('gradientType', defaultValue: 'halfDark').toString();
  }

  Future<void> updateTheme(String theme) async {
    currentTheme.value = theme;
    await Hive.box('settings').put('theme', theme);
  }

  Future<void> toggleDarkMode(bool value) async {
    isDarkMode.value = value;
    await Hive.box('settings').put('darkMode', value);
  }

  Future<void> updateAccentColor(int color) async {
    accentColor.value = color;
    await Hive.box('settings').put('accentColor', color);
  }

  Future<void> updateGradientType(String type) async {
    gradientType.value = type;
    await Hive.box('settings').put('gradientType', type);
  }

  Future<void> toggleSystemTheme(bool value) async {
    useSystemTheme.value = value;
    await Hive.box('settings').put('useSystemTheme', value);
  }
}
