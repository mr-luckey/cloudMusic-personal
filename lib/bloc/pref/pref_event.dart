part of 'pref_bloc.dart';

abstract class PrefEvent extends Equatable {
  const PrefEvent();

  @override
  List<Object?> get props => [];
}

class PrefPreferredLanguageChanged extends PrefEvent {
  final List preferredLanguage;

  const PrefPreferredLanguageChanged(this.preferredLanguage);

  @override
  List<Object?> get props => [preferredLanguage];
}

class PrefRegionChanged extends PrefEvent {
  final String region;

  const PrefRegionChanged(this.region);

  @override
  List<Object?> get props => [region];
}

class PrefUseProxyChanged extends PrefEvent {
  final bool useProxy;

  const PrefUseProxyChanged(this.useProxy);

  @override
  List<Object?> get props => [useProxy];
}

class PrefSelectionChanged extends PrefEvent {
  const PrefSelectionChanged();
}
