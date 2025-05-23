// Coded by Naseer Ahmed

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:logging/logging.dart';

class SpotifyApi {
  final List<String> _scopes = [
    'user-read-private',
    'user-read-email',
    'playlist-read-private',
    'playlist-read-collaborative',
  ];

  /// You can signup for spotify developer account and get your own clientID and clientSecret incase you don't want to use these
  final String clientID = '08de4eaf71904d1b95254fab3015d711';
  final String clientSecret = '622b4fbad33947c59b95a6ae607de11d';
  final String redirectUrl = 'CloudSpot://spotify/auth';
  final String spotifyApiUrl = 'https://accounts.spotify.com/api';
  final String spotifyApiBaseUrl = 'https://api.spotify.com/v1';
  final String spotifyUserPlaylistEndpoint = '/me/playlists';
  final String spotifyPlaylistTrackEndpoint = '/playlists';
  final String spotifyRegionalChartsEndpoint = '/views/charts-regional';
  final String spotifyFeaturedPlaylistsEndpoint = '/browse/featured-playlists';
  final String spotifyBaseUrl = 'https://accounts.spotify.com';
  final String requestToken = 'https://accounts.spotify.com/api/token';
  final String playerAccessToken =
      'https://open.spotify.com/get_access_token?reason=transport&productType=web_player';

  String requestAuthorization() =>
      'https://accounts.spotify.com/authorize?client_id=$clientID&response_type=code&redirect_uri=$redirectUrl&scope=${_scopes.join('%20')}';

  Future<List<String>> getAccessToken({
    String? code,
    String? refreshToken,
  }) async {
    final Map<String, String> headers = {
      'Authorization':
          "Basic ${base64.encode(utf8.encode("$clientID:$clientSecret"))}",
    };

    Map<String, String>? body;
    if (code != null) {
      body = {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUrl,
      };
    } else if (refreshToken != null) {
      body = {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      };
    }

    if (body == null) {
      return [];
    }

    try {
      final Uri path = Uri.parse(requestToken);
      final response = await post(path, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map result = jsonDecode(response.body) as Map;
        return <String>[
          result['access_token'].toString(),
          result['refresh_token'].toString(),
          result['expires_in'].toString(),
        ];
      } else {
        Logger.root.severe(
          'Error in getAccessToken, called: $path, returned: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      Logger.root.severe('Error in getting spotify access token: $e');
    }
    return [];
  }

  Future<Map> getPlayerAccessToken() async {
    try {
      final Uri path = Uri.parse(playerAccessToken);
      final response = await get(
        path,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.0.0 Safari/537.36',
          'Accept': 'application/json',
          'App-platform': 'WebPlayer',
        },
      );

      if (response.statusCode == 200) {
        final Map result = jsonDecode(response.body) as Map;
        return result;
      } else {
        Logger.root.severe(
          'Error in getPlayerAccessToken, called: $path, returned: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      Logger.root.severe('Error in getting spotify player access token: $e');
    }
    return {};
  }

  Future<List> getUserPlaylists(String accessToken) async {
    try {
      final Uri path =
          Uri.parse('$spotifyApiBaseUrl$spotifyUserPlaylistEndpoint?limit=50');

      final response = await get(
        path,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List playlists = result['items'] as List;
        return playlists;
      } else {
        Logger.root.severe(
          'Error in getUserPlaylists, called: $path, returned: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      Logger.root.severe('Error in getting spotify user playlists: $e');
    }
    return [];
  }

  Future<List> getAllTracksOfPlaylist(
    String accessToken,
    String playlistId,
  ) async {
    final List tracks = [];
    int totalTracks = 100;

    final Map data = await SpotifyApi().getHundredTracksOfPlaylist(
      accessToken,
      playlistId,
      0,
    );
    if (data['tracks'] == null) {
      return [];
    }
    totalTracks = data['total'] as int;
    tracks.addAll(data['tracks'] as List);

    if (totalTracks > 100) {
      for (int i = 1; i * 100 <= totalTracks; i++) {
        final Map data = await SpotifyApi().getHundredTracksOfPlaylist(
          accessToken,
          playlistId,
          i * 100,
        );
        if (data['tracks'] != null) {
          tracks.addAll(data['tracks'] as List);
        }
      }
    }
    return tracks;
  }

  Future<Map> getHundredTracksOfPlaylist(
    String accessToken,
    String playlistId,
    int offset,
  ) async {
    try {
      final Uri path = Uri.parse(
        '$spotifyApiBaseUrl$spotifyPlaylistTrackEndpoint/$playlistId/tracks?limit=100&offset=$offset',
      );
      final response = await get(
        path,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final result = await jsonDecode(response.body);
        final List tracks = result['items'] as List;
        final int total = result['total'] as int;
        return {'tracks': tracks, 'total': total};
      } else {
        Logger.root.severe(
          'Error in getHundredTracksOfPlaylist, called: $path, returned: ${response.statusCode}',
          response.body,
        );
        final jsonRes = jsonDecode(response.body);
        final errorMsg =
            jsonRes['error']['message'] ??= 'Error in getting tracks';
        return {'error': errorMsg};
      }
    } catch (e) {
      Logger.root.severe('Error in getting spotify playlist tracks: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map> searchTrack({
    required String accessToken,
    required String query,
    int limit = 10,
    String type = 'track',
  }) async {
    final Uri path = Uri.parse(
      '$spotifyApiBaseUrl/search?q=$query&type=$type&limit=$limit',
    );

    final response = await get(
      path,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body) as Map;
      return result;
    } else {
      Logger.root.severe(
        'Error in searchTrack, called: $path, returned: ${response.statusCode}',
        response.body,
      );
    }
    return {};
  }

  Future<Map> getTrackDetails(String accessToken, String trackId) async {
    final Uri path = Uri.parse(
      '$spotifyApiBaseUrl/tracks/$trackId',
    );
    final response = await get(
      path,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body) as Map;
      return result;
    } else {
      Logger.root.severe(
        'Error in getTrackDetails, called: $path, returned: ${response.statusCode}',
        response.body,
      );
    }
    return {};
  }

  Future<List<Map>> getFeaturedPlaylists(String accessToken) async {
    try {
      final Uri path = Uri.parse(
        '$spotifyApiBaseUrl/browse/featured-playlists',
      );
      final response = await get(
        path,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );
      final List<Map> songsData = [];
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        await for (final element in result['playlists']['items'] as Stream) {
          songsData.add({
            'name': element['name'],
            'id': element['id'],
            'image': element['images'][0]['url'],
            'description': element['description'],
            'externalUrl': element['external_urls']['spotify'],
            'tracks': await SpotifyApi().getAllTracksOfPlaylist(
              accessToken,
              element['id'].toString(),
            ),
          });
        }
      } else {
        Logger.root.severe(
          'Error in getFeaturedPlaylists, called: $path, returned: ${response.statusCode}',
          response.body,
        );
      }
      return songsData;
    } catch (e) {
      Logger.root.severe('Error in getting spotify featured playlists: $e');
      return List.empty();
    }
  }
}
