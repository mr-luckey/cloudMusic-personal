import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutState extends Equatable {
  final String? appVersion;

  const AboutState({this.appVersion});

  AboutState copyWith({String? appVersion}) {
    return AboutState(appVersion: appVersion ?? this.appVersion);
  }

  @override
  List<Object?> get props => [appVersion];
}

class AboutCubit extends Cubit<AboutState> {
  AboutCubit() : super(const AboutState());

  Future<void> loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    emit(state.copyWith(appVersion: packageInfo.version));
  }
}
