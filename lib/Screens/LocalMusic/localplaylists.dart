// Coded by Naseer Ahmed

import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/textinput_dialog.dart';
import 'package:blackhole/Helpers/audio_query.dart';
import 'package:blackhole/Screens/LocalMusic/downed_songs.dart';
import 'package:flutter/material.dart';
// import 'package:blackhole/localization/app_localizations.dart';

import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';

class LocalPlaylistsController extends GetxController {
  final List<PlaylistModel> initialPlaylistDetails;
  final OfflineAudioQuery offlineAudioQuery;

  LocalPlaylistsController({
    required this.initialPlaylistDetails,
    required this.offlineAudioQuery,
  });

  final playlistDetails = <PlaylistModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    playlistDetails.value = initialPlaylistDetails;
  }

  Future<void> createPlaylist(String name) async {
    await offlineAudioQuery.createPlaylist(name: name);
    final playlists = await offlineAudioQuery.getPlaylists();
    playlistDetails.value = playlists;
  }

  Future<bool> removePlaylist(int playlistId, int index) async {
    if (await offlineAudioQuery.removePlaylist(playlistId: playlistId)) {
      playlistDetails.removeAt(index);
      return true;
    }
    return false;
  }
}

class LocalPlaylists extends StatelessWidget {
  final List<PlaylistModel> playlistDetails;
  final OfflineAudioQuery offlineAudioQuery;

  const LocalPlaylists({
    super.key,
    required this.playlistDetails,
    required this.offlineAudioQuery,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      LocalPlaylistsController(
        initialPlaylistDetails: playlistDetails,
        offlineAudioQuery: offlineAudioQuery,
      ),
      tag: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 5),
          ListTile(
            title: Text(AppLocalizations.of(context)!.createPlaylist),
            leading: Card(
              elevation: 0,
              color: Colors.transparent,
              child: SizedBox.square(
                dimension: 50,
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
            ),
            onTap: () async {
              showTextInputDialog(
                context: context,
                title: AppLocalizations.of(context)!.createNewPlaylist,
                initialText: '',
                keyboardType: TextInputType.name,
                onSubmitted: (String value, BuildContext context) async {
                  if (value.trim() != '') {
                    Navigator.pop(context);
                    await controller.createPlaylist(value);
                  }
                },
              );
            },
          ),
          Obx(
            () => controller.playlistDetails.isEmpty
                ? const SizedBox()
                : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: controller.playlistDetails.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Card(
                          margin: EdgeInsets.zero,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7.0),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: QueryArtworkWidget(
                            id: controller.playlistDetails[index].id,
                            type: ArtworkType.PLAYLIST,
                            keepOldArtwork: true,
                            artworkBorder: BorderRadius.circular(7.0),
                            nullArtworkWidget: ClipRRect(
                              borderRadius: BorderRadius.circular(7.0),
                              child: const Image(
                                fit: BoxFit.cover,
                                height: 50.0,
                                width: 50.0,
                                image: AssetImage('assets/cover.jpg'),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          controller.playlistDetails[index].playlist,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${controller.playlistDetails[index].numOfSongs} ${AppLocalizations.of(context)!.songs}',
                        ),
                        trailing: PopupMenuButton(
                          icon: const Icon(Icons.more_vert_rounded),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(15.0),
                            ),
                          ),
                          onSelected: (int? value) async {
                            if (value == 0) {
                              if (await controller.removePlaylist(
                                controller.playlistDetails[index].id,
                                index,
                              )) {
                                ShowSnackBar().showSnackBar(
                                  context,
                                  '${AppLocalizations.of(context)!.deleted} ${controller.playlistDetails[index].playlist}',
                                );
                              } else {
                                ShowSnackBar().showSnackBar(
                                  context,
                                  AppLocalizations.of(context)!.failedDelete,
                                );
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 0,
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_rounded),
                                  const SizedBox(width: 10.0),
                                  Text(
                                    AppLocalizations.of(context)!.delete,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () async {
                          final songs =
                              await offlineAudioQuery.getPlaylistSongs(
                            controller.playlistDetails[index].id,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DownloadedSongs(
                                title:
                                    controller.playlistDetails[index].playlist,
                                cachedSongs: songs,
                                playlistId:
                                    controller.playlistDetails[index].id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
