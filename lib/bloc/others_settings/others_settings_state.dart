part of 'others_settings_bloc.dart';

class OthersSettingsState extends Equatable {
  final String lang;
  final bool useProxy;
  final int refreshTick;

  const OthersSettingsState({
    required this.lang,
    required this.useProxy,
    this.refreshTick = 0,
  });

  factory OthersSettingsState.initial() {
    final box = Hive.box('settings');
    return OthersSettingsState(
      lang: box.get('lang', defaultValue: 'English') as String,
      useProxy: box.get('useProxy', defaultValue: false) as bool,
    );
  }

  OthersSettingsState copyWith({
    String? lang,
    bool? useProxy,
    int? refreshTick,
  }) {
    return OthersSettingsState(
      lang: lang ?? this.lang,
      useProxy: useProxy ?? this.useProxy,
      refreshTick: refreshTick ?? this.refreshTick,
    );
  }

  @override
  List<Object?> get props => [lang, useProxy, refreshTick];
}
