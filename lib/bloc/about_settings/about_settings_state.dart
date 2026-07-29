part of 'about_settings_bloc.dart';

class AboutSettingsState extends Equatable {
  final String? appVersion;

  const AboutSettingsState({this.appVersion});

  AboutSettingsState copyWith({String? appVersion}) {
    return AboutSettingsState(
      appVersion: appVersion ?? this.appVersion,
    );
  }

  @override
  List<Object?> get props => [appVersion];
}
