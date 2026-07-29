import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

part 'pref_event.dart';
part 'pref_state.dart';

class PrefBloc extends Bloc<PrefEvent, PrefState> {
  PrefBloc()
      : super(PrefState(
          preferredLanguage: Hive.box('settings')
              .get('preferredLanguage', defaultValue: ['English'])
              ?.toList() as List,
          region: Hive.box('settings')
              .get('region', defaultValue: 'Pakistan') as String,
          useProxy: Hive.box('settings')
              .get('useProxy', defaultValue: false) as bool,
          isSelected: [true, false],
        )) {
    on<PrefPreferredLanguageChanged>(_onPreferredLanguageChanged);
    on<PrefRegionChanged>(_onRegionChanged);
    on<PrefUseProxyChanged>(_onUseProxyChanged);
    on<PrefSelectionChanged>(_onSelectionChanged);
  }

  void _onPreferredLanguageChanged(
    PrefPreferredLanguageChanged event,
    Emitter<PrefState> emit,
  ) {
    emit(state.copyWith(preferredLanguage: event.preferredLanguage));
  }

  void _onRegionChanged(PrefRegionChanged event, Emitter<PrefState> emit) {
    emit(state.copyWith(region: event.region));
  }

  void _onUseProxyChanged(PrefUseProxyChanged event, Emitter<PrefState> emit) {
    emit(state.copyWith(useProxy: event.useProxy));
  }

  void _onSelectionChanged(PrefSelectionChanged event, Emitter<PrefState> emit) {
    emit(state.copyWith());
  }
}
