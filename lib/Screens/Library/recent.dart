// Coded by Naseer Ahmed

import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/image_card.dart';
import 'package:blackhole/CustomWidgets/like_button.dart';
import 'package:blackhole/Services/player_service.dart';
import 'package:blackhole/bloc/recent/recent_bloc.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/localization/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecentlyPlayed extends StatefulWidget {
  @override
  _RecentlyPlayedState createState() => _RecentlyPlayedState();
}

class _RecentlyPlayedState extends State<RecentlyPlayed> {
  late final RecentBloc _recentBloc;

  @override
  void initState() {
    _recentBloc = RecentBloc();
    _recentBloc.add(const RecentLoadRequested());
    super.initState();
  }

  @override
  void dispose() {
    _recentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecentBloc, RecentState>(
      bloc: _recentBloc,
      builder: (context, state) {
        return GradientContainer(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.lastSession),
              centerTitle: true,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.secondary,
              elevation: 0,
              actions: [
                IconButton(
                  onPressed: () {
                    _recentBloc.add(const RecentClearAll());
                  },
                  tooltip: AppLocalizations.of(context)!.clearAll,
                  icon: const Icon(Icons.clear_all_rounded),
                ),
              ],
            ),
            body: !state.isLoaded
                ? const Center(child: CircularProgressIndicator())
                : state.songs.isEmpty
                    ? emptyScreen(
                        context,
                        3,
                        AppLocalizations.of(context)!.nothingTo,
                        15,
                        AppLocalizations.of(context)!.showHere,
                        50.0,
                        AppLocalizations.of(context)!.playSomething,
                        23.0,
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
                              : Dismissible(
                                  key: Key(state.songs[index]['id'].toString()),
                                  direction: DismissDirection.endToStart,
                                  background: const ColoredBox(
                                    color: Colors.redAccent,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 15.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Icon(Icons.delete_outline_rounded),
                                        ],
                                      ),
                                    ),
                                  ),
                                  onDismissed: (direction) {
                                    _recentBloc.add(
                                      RecentSongDismissed(index: index),
                                    );
                                  },
                                  child: ListTile(
                                    leading: imageCard(
                                      imageUrl:
                                          state.songs[index]['image'].toString(),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        LikeButton(
                                          mediaItem: null,
                                          data: state.songs[index] as Map,
                                        ),
                                      ],
                                    ),
                                    title: Text(
                                      '${state.songs[index]["title"]}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '${state.songs[index]["artist"]}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () {
                                      PlayerInvoke.init(
                                        songsList: state.songs,
                                        index: index,
                                        isOffline: false,
                                      );
                                    },
                                  ),
                                );
                        },
                      ),
          ),
        );
      },
    );
  }
}
