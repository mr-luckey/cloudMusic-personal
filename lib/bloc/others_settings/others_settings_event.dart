part of 'others_settings_bloc.dart';

abstract class OthersSettingsEvent extends Equatable {
  const OthersSettingsEvent();

  @override
  List<Object?> get props => [];
}

class OthersLanguageChanged extends OthersSettingsEvent {
  final String lang;

  const OthersLanguageChanged(this.lang);

  @override
  List<Object?> get props => [lang];
}

class OthersUseProxyChanged extends OthersSettingsEvent {
  final bool useProxy;

  const OthersUseProxyChanged(this.useProxy);

  @override
  List<Object?> get props => [useProxy];
}

class OthersProxySettingsUpdated extends OthersSettingsEvent {
  const OthersProxySettingsUpdated();
}

class OthersCacheCleared extends OthersSettingsEvent {
  const OthersCacheCleared();
}
