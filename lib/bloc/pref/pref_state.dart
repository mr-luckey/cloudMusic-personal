part of 'pref_bloc.dart';

class PrefState extends Equatable {
  final List preferredLanguage;
  final String region;
  final bool useProxy;
  final List<bool> isSelected;

  const PrefState({
    required this.preferredLanguage,
    required this.region,
    required this.useProxy,
    required this.isSelected,
  });

  PrefState copyWith({
    List? preferredLanguage,
    String? region,
    bool? useProxy,
    List<bool>? isSelected,
  }) {
    return PrefState(
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      region: region ?? this.region,
      useProxy: useProxy ?? this.useProxy,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [preferredLanguage, region, useProxy, isSelected];
}
