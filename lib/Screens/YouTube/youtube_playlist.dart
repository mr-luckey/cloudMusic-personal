// Coded by Naseer Ahmed

import 'dart:async';

import 'package:blackhole/CustomWidgets/bouncy_playlist_header_scroll_view.dart';
import 'package:blackhole/CustomWidgets/copy_clipboard.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/image_card.dart';
import 'package:blackhole/CustomWidgets/playlist_popupmenu.dart';
import 'package:blackhole/CustomWidgets/song_tile_trailing_menu.dart';
import 'package:blackhole/Services/player_service.dart';
import 'package:blackhole/bloc/youtube_playlist/youtube_playlist_bloc.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/localization/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

class YouTubePlaylist extends StatefulWidget {
  final String playlistId;
  final String type;

  const YouTubePlaylist({
    super.key,
    required this.playlistId,
    this.type = 'playlist',
  });

  @override
  _YouTubePlaylistState createState() => _YouTubePlaylistState();
}

class _YouTubePlaylistState extends State<YouTubePlaylist> {
  final ScrollController _scrollController = ScrollController();
  late final YouTubePlaylistBloc _bloc;
  bool isSharePopupShown = false;

  @override
  void initState() {
    _bloc = YouTubePlaylistBloc();
    _bloc.add(YouTubePlaylistLoadRequested(
      playlistId: widget.playlistId,
      type: widget.type,
    ));
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext cntxt) {
    return BlocConsumer<YouTubePlaylistBloc, YouTubePlaylistState>(
      bloc: _bloc,
      listener: (context, state) {
        if (state.formattedResponse != null) {
          PlayerInvoke.init(
            songsList: [state.formattedResponse],
            index: 0,
            isOffline: false,
          );
          _bloc.add(const YouTubePlaylistLoadingFinished());
        }
        if (state.playAllTriggered && state.formattedPlayList != null) {
          PlayerInvoke.init(
            songsList: state.formattedPlayList!,
            index: 0,
            isOffline: false,
            recommend: false,
          );
          _bloc.add(const YouTubePlaylistLoadingFinished());
        }
        if (state.shuffleTriggered && state.formattedPlayList != null) {
          PlayerInvoke.init(
            songsList: state.formattedPlayList!,
            index: 0,
            isOffline: false,
            recommend: false,
          );
          _bloc.add(const YouTubePlaylistLoadingFinished());
        }
      },
      builder: (context, state) {
        return GradientContainer(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                if (state.status == YouTubePlaylistStatus.loading ||
                    state.status == YouTubePlaylistStatus.initial)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else
                  BouncyPlaylistHeaderScrollView(
                    scrollController: _scrollController,
                    title: state.playlistName,
                    subtitle: state.playlistSubtitle,
                    secondarySubtitle: state.playlistSecondarySubtitle,
                    imageUrl: state.playlistImage,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.share_rounded),
                        tooltip: AppLocalizations.of(context)!.share,
                        onPressed: () {
                          if (!isSharePopupShown) {
                            isSharePopupShown = true;
                            Share.share(
                              'https://youtube.com/playlist?list=${widget.playlistId}',
                            ).whenComplete(() {
                              Timer(const Duration(milliseconds: 500), () {
                                isSharePopupShown = false;
                              });
                            });
                          }
                        },
                      ),
                      PlaylistPopupMenu(
                        data: state.searchedList,
                        title: state.playlistName,
                      ),
                    ],
                    onPlayTap: () {
                      _bloc.add(const YouTubePlaylistPlayAllTapped());
                    },
                    onShuffleTap: () {
                      _bloc.add(const YouTubePlaylistShuffleTapped());
                    },
                    sliverList: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          if (state.searchedList.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 20.0,
                                top: 5.0,
                                bottom: 5.0,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.songs,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.0,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
                          ...state.searchedList.map(
                            (Map entry) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: 5.0,
                                ),
                                child: ListTile(
                                  leading: widget.type == 'album'
                                      ? null
                                      : imageCard(
                                          imageUrl: entry['image'].toString(),
                                        ),
                                  title: Text(
                                    entry['title'].toString(),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onLongPress: () {
                                    copyToClipboard(
                                      context: context,
                                      text: entry['title'].toString(),
                                    );
                                  },
                                  subtitle: entry['subtitle'] == ''
                                      ? null
                                      : Text(
                                          entry['subtitle'].toString(),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                  onTap: () {
                                    _bloc.add(YouTubePlaylistSongTapped(
                                        entry: entry));
                                  },
                                  trailing:
                                      YtSongTileTrailingMenu(data: entry),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                if (state.isProcessing)
                  Center(
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).width / 2,
                      width: MediaQuery.sizeOf(context).width / 2,
                      child: Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: GradientContainer(
                          child: Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.useHome,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                    Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                  ),
                                  strokeWidth: 5,
                                ),
                                Text(
                                  AppLocalizations.of(context)!
                                      .fetchingStream,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
