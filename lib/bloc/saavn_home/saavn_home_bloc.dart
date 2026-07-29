import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/Helpers/format.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'saavn_home_event.dart';
part 'saavn_home_state.dart';

class SaavnHomeBloc extends Bloc<SaavnHomeEvent, SaavnHomeState> {
  SaavnHomeBloc() : super(SaavnHomeState.initial()) {
    on<SaavnHomeLoadRequested>(_onLoadRequested);
    on<SaavnHomeSectionBlacklisted>(_onSectionBlacklisted);
    on<SaavnHomeLikedRadioToggled>(_onLikedRadioToggled);
  }

  List _buildLists(Map data) {
    final lists = ['recent', 'playlist', ...?data['collections'] as List?];
    lists.insert((lists.length / 2).round(), 'likedArtists');
    return lists;
  }

  Future<void> _onLoadRequested(
    SaavnHomeLoadRequested event,
    Emitter<SaavnHomeState> emit,
  ) async {
    emit(state.copyWith(status: SaavnHomeStatus.loading));

    Map data = Map.from(state.data);
    Map receivedData = await SaavnAPI().fetchHomePageData();
    if (receivedData.isNotEmpty) {
      Hive.box('cache').put('homepage', receivedData);
      data = receivedData;
      emit(
        state.copyWith(
          data: Map.from(data),
          lists: _buildLists(data),
          status: SaavnHomeStatus.loaded,
        ),
      );
    }

    receivedData = await FormatResponse.formatPromoLists(data);
    if (receivedData.isNotEmpty) {
      Hive.box('cache').put('homepage', receivedData);
      data = receivedData;
      emit(
        state.copyWith(
          data: Map.from(data),
          lists: _buildLists(data),
          status: SaavnHomeStatus.loaded,
        ),
      );
    } else if (state.status == SaavnHomeStatus.loading) {
      emit(state.copyWith(status: SaavnHomeStatus.loaded));
    }
  }

  void _onSectionBlacklisted(
    SaavnHomeSectionBlacklisted event,
    Emitter<SaavnHomeState> emit,
  ) {
    final blacklistedHomeSections = List.from(state.blacklistedHomeSections);
    blacklistedHomeSections.add(event.sectionTitle);
    Hive.box('settings').put(
      'blacklistedHomeSections',
      blacklistedHomeSections,
    );
    emit(state.copyWith(blacklistedHomeSections: blacklistedHomeSections));
  }

  void _onLikedRadioToggled(
    SaavnHomeLikedRadioToggled event,
    Emitter<SaavnHomeState> emit,
  ) {
    final likedRadio = List.from(state.likedRadio);
    if (likedRadio.contains(event.item)) {
      likedRadio.remove(event.item);
    } else {
      likedRadio.add(event.item);
    }
    Hive.box('settings').put('likedRadio', likedRadio);
    emit(state.copyWith(likedRadio: likedRadio));
  }
}
