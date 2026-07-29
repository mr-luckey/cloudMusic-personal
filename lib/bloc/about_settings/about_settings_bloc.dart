import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'about_settings_event.dart';
part 'about_settings_state.dart';

class AboutSettingsBloc extends Bloc<AboutSettingsEvent, AboutSettingsState> {
  AboutSettingsBloc() : super(const AboutSettingsState()) {
    on<AboutSettingsLoadAppVersion>(_onLoadAppVersion);
  }

  Future<void> _onLoadAppVersion(
    AboutSettingsLoadAppVersion event,
    Emitter<AboutSettingsState> emit,
  ) async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    emit(state.copyWith(appVersion: packageInfo.version));
  }
}
