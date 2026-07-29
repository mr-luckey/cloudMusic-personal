// Coded by Naseer Ahmed

import 'package:blackhole/CustomWidgets/box_switch_tile.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/picker.dart';
import 'package:blackhole/Services/ext_storage_provider.dart';
import 'package:blackhole/bloc/download_settings/download_settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/localization/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DownloadSettingsBloc(),
      child: const _DownloadPageContent(),
    );
  }
}

class _DownloadPageContent extends StatelessWidget {
  const _DownloadPageContent();

  @override
  Widget build(BuildContext context) {
    final Box settingsBox = Hive.box('settings');

    return BlocBuilder<DownloadSettingsBloc, DownloadSettingsState>(
      builder: (context, state) {
        return GradientContainer(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              centerTitle: true,
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .down,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              iconTheme: IconThemeData(
                color: Theme.of(context).iconTheme.color,
              ),
            ),
            body: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(10.0),
              children: [
                ListTile(
                  title: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .downQuality,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .downQualitySub,
                  ),
                  onTap: () {},
                  trailing: DropdownButton(
                    value: state.downloadQuality,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                    underline: const SizedBox(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        context.read<DownloadSettingsBloc>().add(
                              DownloadQualityChanged(newValue),
                            );
                      }
                    },
                    items: <String>['96 kbps', '160 kbps', '320 kbps']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                        ),
                      );
                    }).toList(),
                  ),
                  dense: true,
                ),
                ListTile(
                  title: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .ytDownQuality,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .ytDownQualitySub,
                  ),
                  onTap: () {},
                  trailing: DropdownButton(
                    value: state.ytDownloadQuality,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                    underline: const SizedBox(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        context.read<DownloadSettingsBloc>().add(
                              YtDownloadQualityChanged(newValue),
                            );
                      }
                    },
                    items: <String>['Low', 'High']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                        ),
                      );
                    }).toList(),
                  ),
                  dense: true,
                ),
                ListTile(
                  title: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .downLocation,
                  ),
                  subtitle: Text(state.downloadPath),
                  trailing: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.grey[700],
                    ),
                    onPressed: () async {
                      final path = await ExtStorageProvider.getExtStorage(
                            dirName: 'Music',
                            writeAccess: true,
                          ) ??
                          '/storage/emulated/0/Music';
                      if (context.mounted) {
                        context.read<DownloadSettingsBloc>().add(
                              DownloadPathChanged(path),
                            );
                      }
                    },
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!
                          .reset,
                    ),
                  ),
                  onTap: () async {
                    final String temp = await Picker.selectFolder(
                      context: context,
                      message: AppLocalizations.of(
                        context,
                      )!
                          .selectDownLocation,
                    );
                    if (temp.trim() != '') {
                      if (context.mounted) {
                        context.read<DownloadSettingsBloc>().add(
                              DownloadPathChanged(temp),
                            );
                      }
                    } else {
                      ShowSnackBar().showSnackBar(
                        context,
                        AppLocalizations.of(
                          context,
                        )!
                            .noFolderSelected,
                      );
                    }
                  },
                  dense: true,
                ),
                ListTile(
                  title: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .downFilename,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .downFilenameSub,
                  ),
                  dense: true,
                  onTap: () {
                    showModalBottomSheet(
                      isDismissible: true,
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (BuildContext sheetContext) {
                        return BottomGradientContainer(
                          borderRadius: BorderRadius.circular(
                            20.0,
                          ),
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(
                              0,
                              10,
                              0,
                              10,
                            ),
                            children: [
                              CheckboxListTile(
                                activeColor:
                                    Theme.of(context).colorScheme.secondary,
                                title: Text(
                                  '${AppLocalizations.of(context)!.title} - ${AppLocalizations.of(context)!.artist}',
                                ),
                                value: state.downFilename == 0,
                                selected: state.downFilename == 0,
                                onChanged: (bool? val) {
                                  if (val ?? false) {
                                    settingsBox.put('downFilename', 0);
                                    context.read<DownloadSettingsBloc>().add(
                                          const DownFilenameChanged(0),
                                        );
                                    Navigator.pop(sheetContext);
                                  }
                                },
                              ),
                              CheckboxListTile(
                                activeColor:
                                    Theme.of(context).colorScheme.secondary,
                                title: Text(
                                  '${AppLocalizations.of(context)!.artist} - ${AppLocalizations.of(context)!.title}',
                                ),
                                value: state.downFilename == 1,
                                selected: state.downFilename == 1,
                                onChanged: (val) {
                                  if (val ?? false) {
                                    settingsBox.put('downFilename', 1);
                                    context.read<DownloadSettingsBloc>().add(
                                          const DownFilenameChanged(1),
                                        );
                                    Navigator.pop(sheetContext);
                                  }
                                },
                              ),
                              CheckboxListTile(
                                activeColor:
                                    Theme.of(context).colorScheme.secondary,
                                title: Text(
                                  AppLocalizations.of(context)!.title,
                                ),
                                value: state.downFilename == 2,
                                selected: state.downFilename == 2,
                                onChanged: (val) {
                                  if (val ?? false) {
                                    settingsBox.put('downFilename', 2);
                                    context.read<DownloadSettingsBloc>().add(
                                          const DownFilenameChanged(2),
                                        );
                                    Navigator.pop(sheetContext);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                BoxSwitchTile(
                  title: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .createAlbumFold,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .createAlbumFoldSub,
                  ),
                  keyName: 'createDownloadFolder',
                  isThreeLine: true,
                  defaultValue: false,
                ),
                BoxSwitchTile(
                  title: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .createYtFold,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .createYtFoldSub,
                  ),
                  keyName: 'createYoutubeFolder',
                  isThreeLine: true,
                  defaultValue: false,
                ),
                BoxSwitchTile(
                  title: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .downLyrics,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .downLyricsSub,
                  ),
                  keyName: 'downloadLyrics',
                  defaultValue: false,
                  isThreeLine: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
