// Coded by Naseer Ahmed

import 'dart:io';

import 'package:blackhole/CustomWidgets/drawer.dart';
import 'package:blackhole/Screens/Library/liked.dart';
import 'package:blackhole/Screens/LocalMusic/downed_songs.dart';
import 'package:blackhole/Screens/LocalMusic/downed_songs_desktop.dart';
import 'package:blackhole/Screens/LocalMusic/local_song.dart';
import 'package:blackhole/Screens/Top%20Charts/top.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool rotated = MediaQuery.sizeOf(context).height < screenWidth;
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        AppBar(
          title: Text(
            AppLocalizations.of(context)!.library,
            style: TextStyle(
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          // leading: rotated ? null : homeDrawer(context: context),
        ),
        LibraryTile(
          title: AppLocalizations.of(context)!.nowPlaying,
          icon: Icons.queue_music_rounded,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pushNamed('/nowplaying');

            // Navigator.pushNamed(context, '/nowplaying');
          },
        ),
        LibraryTile(
          title: AppLocalizations.of(context)!.lastSession,
          icon: Icons.history_rounded,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pushNamed('/recent');

            // Navigator.pushNamed(context, '/recent');
          },
        ),
        LibraryTile(
          title: AppLocalizations.of(context)!.favorites,
          icon: Icons.favorite_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LikedSongs(
                  playlistName: 'Favorite Songs',
                  showName: AppLocalizations.of(context)!.favSongs,
                ),
              ),
            );
          },
        ), //TODO: Copy this tile code and setuo this tile code to main screen
        LibraryTile(
          title: AppLocalizations.of(context)!.myMusic,
          icon: MdiIcons.folderMusic,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => (Platform.isWindows ||
                        Platform.isLinux ||
                        Platform.isAndroid)
                    ? SongsWidget()
                    : const DownloadedSongs(
                        showPlaylists: true,
                      ),
              ),
            );
          },
        ),
        LibraryTile(
          title: AppLocalizations.of(context)!.downs,
          icon: Icons.download_done_rounded,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pushNamed('/downloads');
            // Navigator.pushNamed(context, '/downloads');
          },
        ),
        LibraryTile(
          title: AppLocalizations.of(context)!.playlists,
          icon: Icons.playlist_play_rounded,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pushNamed('/playlists');

            // Navigator.pushNamed(context, '/playlists');
          },
        ),
        LibraryTile(
          title: AppLocalizations.of(context)!.stats,
          icon: Icons.auto_graph_rounded,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pushNamed('/stats');

            // Navigator.pushNamed(context, '/stats');
          },
        ),
      ],
    );
  }
}

class LibraryTile extends StatelessWidget {
  const LibraryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).iconTheme.color,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: Theme.of(context).iconTheme.color,
              ),
            )
          : null,
      leading: Icon(
        icon,
        color: Theme.of(context).iconTheme.color,
      ),
      onTap: onTap,
    );
  }
}
