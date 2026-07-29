// Coded by Naseer Ahmed

import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/image_card.dart';
import 'package:blackhole/Services/player_service.dart';
import 'package:blackhole/bloc/show_songs/show_songs_bloc.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/localization/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SongsList extends StatefulWidget {
  final List data;
  final bool offline;
  final String? title;
  const SongsList({
    super.key,
    required this.data,
    required this.offline,
    this.title,
  });
  @override
  _SongsListState createState() => _SongsListState();
}

class _SongsListState extends State<SongsList> {
  late final ShowSongsBloc _showSongsBloc;

  @override
  void initState() {
    _showSongsBloc = ShowSongsBloc();
    _showSongsBloc.add(ShowSongsLoadRequested(
      data: widget.data,
      offline: widget.offline,
    ));
    super.initState();
  }

  @override
  void dispose() {
    _showSongsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShowSongsBloc, ShowSongsState>(
      bloc: _showSongsBloc,
      builder: (context, state) {
        return GradientContainer(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(widget.title ?? AppLocalizations.of(context)!.songs),
              actions: [
                PopupMenuButton(
                  icon: const Icon(Icons.sort_rounded),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                  onSelected: (int value) {
                    _showSongsBloc.add(ShowSongsSortChanged(value: value));
                  },
                  itemBuilder: (context) {
                    final List<String> sortTypes = [
                      AppLocalizations.of(context)!.displayName,
                      AppLocalizations.of(context)!.dateAdded,
                      AppLocalizations.of(context)!.album,
                      AppLocalizations.of(context)!.artist,
                      AppLocalizations.of(context)!.duration,
                    ];
                    final List<String> orderTypes = [
                      AppLocalizations.of(context)!.inc,
                      AppLocalizations.of(context)!.dec,
                    ];
                    final menuList = <PopupMenuEntry<int>>[];
                    menuList.addAll(
                      sortTypes
                          .map(
                            (e) => PopupMenuItem(
                              value: sortTypes.indexOf(e),
                              child: Row(
                                children: [
                                  if (state.sortValue == sortTypes.indexOf(e))
                                    Icon(
                                      Icons.check_rounded,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.grey[700],
                                    )
                                  else
                                    const SizedBox(),
                                  const SizedBox(width: 10),
                                  Text(
                                    e,
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    );
                    menuList.add(
                      const PopupMenuDivider(
                        height: 10,
                      ),
                    );
                    menuList.addAll(
                      orderTypes
                          .map(
                            (e) => PopupMenuItem(
                              value: sortTypes.length + orderTypes.indexOf(e),
                              child: Row(
                                children: [
                                  if (state.orderValue ==
                                      orderTypes.indexOf(e))
                                    Icon(
                                      Icons.check_rounded,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.grey[700],
                                    )
                                  else
                                    const SizedBox(),
                                  const SizedBox(width: 10),
                                  Text(
                                    e,
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    );
                    return menuList;
                  },
                ),
              ],
              centerTitle: true,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.secondary,
              elevation: 0,
            ),
            body: !state.isProcessed
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    shrinkWrap: true,
                    itemCount: state.songs.length,
                    itemExtent: 70.0,
                    itemBuilder: (context, index) {
                      return state.songs.isEmpty
                          ? const SizedBox()
                          : ListTile(
                              leading: imageCard(
                                localImage: state.offline,
                                imageUrl: state.offline
                                    ? state.songs[index]['image'].toString()
                                    : state.songs[index]['image'].toString(),
                              ),
                              title: Text(
                                '${state.songs[index]['title']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${state.songs[index]['artist']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                PlayerInvoke.init(
                                  songsList: state.songs,
                                  index: index,
                                  isOffline: state.offline,
                                  fromDownloads: state.offline,
                                  recommend: !state.offline,
                                );
                              },
                            );
                    },
                  ),
          ),
        );
      },
    );
  }
}
