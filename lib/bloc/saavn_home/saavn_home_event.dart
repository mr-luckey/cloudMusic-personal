part of 'saavn_home_bloc.dart';

abstract class SaavnHomeEvent extends Equatable {
  const SaavnHomeEvent();

  @override
  List<Object?> get props => [];
}

class SaavnHomeLoadRequested extends SaavnHomeEvent {
  const SaavnHomeLoadRequested();
}

class SaavnHomeSectionBlacklisted extends SaavnHomeEvent {
  final String sectionTitle;

  const SaavnHomeSectionBlacklisted(this.sectionTitle);

  @override
  List<Object?> get props => [sectionTitle];
}

class SaavnHomeLikedRadioToggled extends SaavnHomeEvent {
  final Map item;

  const SaavnHomeLikedRadioToggled(this.item);

  @override
  List<Object?> get props => [item];
}
