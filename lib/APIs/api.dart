// // Coded by Naseer Ahmed

// import 'dart:convert';

// import 'package:blackhole/Helpers/format.dart';
// import 'package:hive/hive.dart';
// import 'package:http/http.dart';
// import 'package:logging/logging.dart';

// class SaavnAPI {
//   List preferredLanguages = Hive.box('settings')
//       .get('preferredLanguage', defaultValue: ['Hindi']) as List;
//   Map<String, String> headers = {};
//   String baseUrl = 'www.jiosaavn.com';
//   String apiStr = '/api.php?_format=json&_marker=0&api_version=4&ctx=web6dot0';
//   Box settingsBox = Hive.box('settings');
//   Map<String, String> endpoints = {
//     'homeData': '__call=webapi.getLaunchData',
//     'topSearches': '__call=content.getTopSearches',
//     'fromToken': '__call=webapi.get',
//     'featuredRadio': '__call=webradio.createFeaturedStation',
//     'artistRadio': '__call=webradio.createArtistStation',
//     'entityRadio': '__call=webradio.createEntityStation',
//     'radioSongs': '__call=webradio.getSong',
//     'songDetails': '__call=song.getDetails',
//     'playlistDetails': '__call=playlist.getDetails',
//     'albumDetails': '__call=content.getAlbumDetails',
//     'getResults': '__call=search.getResults',
//     'albumResults': '__call=search.getAlbumResults',
//     'artistResults': '__call=search.getArtistResults',
//     'playlistResults': '__call=search.getPlaylistResults',
//     'getReco': '__call=reco.getreco',
//     'getAlbumReco': '__call=reco.getAlbumReco', // still not used
//     'artistOtherTopSongs':
//         '__call=search.artistOtherTopSongs', // still not used
//   };

//   Future<Response> getResponse(
//     String params, {
//     bool usev4 = true,
//     bool useProxy = true,
//   }) async {
//     print('Fetching Saavn API with params: $params test 1 api');
//     Uri url;
//     print('Fetching Saavn API with params: $params test 2 api');
//     if (!usev4) {
//       print("if is running");
//       url = Uri.https(
//         baseUrl,
//         '$apiStr&$params'.replaceAll('&api_version=4', ''),
//       );
//     } else {
//       print('Fetching Saavn API with params: $params test 3 api');
//       url = Uri.https(baseUrl, '$apiStr&$params');
//       print(url);
//     }
//     print("proxy usage: ");
//     print(useProxy);
//     preferredLanguages =
//         preferredLanguages.map((lang) => lang.toLowerCase()).toList();
//     print("testing bug 1");
//     final String languageHeader = 'L=${preferredLanguages.join('%2C')}';
//     print("testing bug 2");
//     headers = {'cookie': languageHeader, 'Accept': '*/*'};
//     print("testing bug 3");

//     if (settingsBox.get('useProxy', defaultValue: false) as bool) {
//       print("testing bug 4");

//       final String proxyIP =
//           settingsBox.get('proxyIp', defaultValue: '103.47.67.134').toString();
//       print("testing bug 5");

//       final proxyHeaders = headers;
//       print("testing bug 6");

//       proxyHeaders['X-FORWARDED-FOR'] = proxyIP;
//       print('Proxy Call final headers before call: $proxyHeaders');
//       print("Proxy Call final URL before call: $url");
//       return get(url, headers: proxyHeaders).onError((error, stackTrace) {
//         return Response(
//           {
//             'status': 'failure',
//             'error': error.toString(),
//           }.toString(),
//           404,
//         );
//       });
//     }
//     print('WithoutProxy Call final headers before call: $headers');
//     print("WithoutProxy Call final URL before call: $url");
//     print("testing bug 7");
//     return get(url, headers: headers).onError((error, stackTrace) {
//       return Response(
//         {
//           'status': 'failure',
//           'error': error.toString(),
//         }.toString(),
//         404,
//       );
//     });
//   }

//   Future<Map> fetchHomePageData() async {
//     Map result = {};
//     try {
//       final res = await getResponse(endpoints['homeData']!, useProxy: false);
//       if (res.statusCode == 200) {
//         final Map data = json.decode(res.body) as Map;
//         result = await FormatResponse.formatHomePageData(data);
//       }
//     } catch (e) {
//       Logger.root.severe('Error in fetchHomePageData: $e');
//     }
//     return result;
//   }

//   Future<Map> getSongFromToken(
//     String token,
//     String type, {
//     int n = 10,
//     int p = 1,
//   }) async {
//     if (n == -1) {
//       final String params =
//           "token=$token&type=$type&n=5&p=$p&${endpoints['fromToken']}";
//       try {
//         final res = await getResponse(params);
//         if (res.statusCode == 200) {
//           final Map getMain = json.decode(res.body) as Map;
//           final String count = getMain['list_count'].toString();
//           final String params2 =
//               "token=$token&type=$type&n=$count&p=$p&${endpoints['fromToken']}";
//           final res2 = await getResponse(params2);
//           if (res2.statusCode == 200) {
//             final Map getMain2 = json.decode(res2.body) as Map;
//             final List responseList = ((type == 'album' || type == 'playlist')
//                 ? getMain2['list']
//                 : getMain2['songs']) as List;
//             final result = {
//               'songs':
//                   await FormatResponse.formatSongsResponse(responseList, type),
//               'title': getMain2['title'],
//             };
//             return result;
//           } else {
//             Logger.root.severe(
//               'getSongFromToken with -1 got res2 with ${res2.statusCode}: ${res2.body}',
//             );
//           }
//         } else {
//           Logger.root.severe(
//             'getSongFromToken with -1 got ${res.statusCode}: ${res.body}',
//           );
//         }
//       } catch (e) {
//         Logger.root.severe('Error in getSongFromToken with -1: $e');
//       }
//       return {'songs': List.empty()};
//     } else {
//       final String params =
//           "token=$token&type=$type&n=$n&p=$p&${endpoints['fromToken']}";
//       try {
//         final res = await getResponse(params);
//         if (res.statusCode == 200) {
//           final Map getMain = json.decode(res.body) as Map;
//           if (getMain['status'] == 'failure') {
//             Logger.root.severe('Error in getSongFromToken response: $getMain');
//             return {'songs': List.empty()};
//           }
//           if (type == 'album' || type == 'playlist') {
//             return getMain;
//           }
//           if (type == 'show') {
//             final List responseList = getMain['episodes'] as List;
//             return {
//               'songs':
//                   await FormatResponse.formatSongsResponse(responseList, type),
//             };
//           }
//           if (type == 'mix') {
//             final List responseList = getMain['list'] as List;
//             return {
//               'songs':
//                   await FormatResponse.formatSongsResponse(responseList, type),
//             };
//           }
//           final List responseList = getMain['songs'] as List;
//           return {
//             'songs':
//                 await FormatResponse.formatSongsResponse(responseList, type),
//             'title': getMain['title'],
//           };
//         }
//       } catch (e) {
//         Logger.root.severe('Error in getSongFromToken: $e');
//       }
//       return {'songs': List.empty()};
//     }
//   }

//   Future<List> getReco(String pid) async {
//     print('Getting recommendations for pid: $pid');
//     final String params = "${endpoints['getReco']}&pid=$pid";
//     print('Params for getReco: $params');
//     final res = await getResponse(params);
//     if (res.statusCode == 200 && res.body.isNotEmpty) {
//       print('getReco response body: ${res.statusCode}, ${res.body}');
//       final List getMain = json.decode(res.body) as List;
//       return FormatResponse.formatSongsResponse(getMain, 'song');
//     } else {
//       Logger.root.severe(
//         'Error in getReco returned status: ${res.statusCode}, response: ${res.body}',
//       );
//     }
//     return List.empty();
//   }

//   Future<String?> createRadio({
//     required List<String> names,
//     required String stationType,
//     String? language,
//   }) async {
//     String? params;
//     if (stationType == 'featured') {
//       params =
//           "name=${names[0]}&language=$language&${endpoints['featuredRadio']}";
//     }
//     if (stationType == 'artist') {
//       params =
//           "name=${names[0]}&query=${names[0]}&language=$language&${endpoints['artistRadio']}";
//     }
//     if (stationType == 'entity') {
//       params =
//           'entity_id=${names.map((e) => '"$e"').toList()}&entity_type=queue&${endpoints["entityRadio"]}';
//     }

//     final res = await getResponse(params!);
//     if (res.statusCode == 200) {
//       final Map getMain = json.decode(res.body) as Map;
//       return getMain['stationid']?.toString();
//     }
//     return null;
//   }

//   Future<List> getRadioSongs({
//     required String stationId,
//     int count = 20,
//     int next = 1,
//   }) async {
//     if (count > 0) {
//       final String params =
//           "stationid=$stationId&k=$count&next=$next&${endpoints['radioSongs']}";
//       final res = await getResponse(params);
//       if (res.statusCode == 200) {
//         final Map getMain = json.decode(res.body) as Map;
//         final List responseList = [];
//         if (getMain['error'] != null && getMain['error'] != '') {
//           return [];
//         }
//         for (int i = 0; i < count; i++) {
//           responseList.add(getMain[i.toString()]['song']);
//         }
//         return FormatResponse.formatSongsResponse(responseList, 'song');
//       }
//       return [];
//     }
//     return [];
//   }

//   Future<List<String>> getTopSearches() async {
//     try {
//       final res = await getResponse(endpoints['topSearches']!);
//       if (res.statusCode == 200) {
//         final List getMain = json.decode(res.body) as List;
//         return getMain.map((element) {
//           return element['title'].toString();
//         }).toList();
//       }
//     } catch (e) {
//       Logger.root.severe('Error in getTopSearches: $e');
//     }
//     return List.empty();
//   }

//   Future<Map> fetchSongSearchResults({
//     required String searchQuery,
//     int count = 20,
//     int page = 1,
//   }) async {
//     final String params =
//         'p=$page&q=$searchQuery&n=$count&${endpoints["getResults"]}';
//     try {
//       final res = await getResponse(params);
//       if (res.statusCode == 200) {
//         final Map getMain = json.decode(res.body) as Map;
//         final List responseList = getMain['results'] as List;
//         final finalSongs =
//             await FormatResponse.formatSongsResponse(responseList, 'song');
//         if (finalSongs.length > count) {
//           finalSongs.removeRange(count, finalSongs.length);
//         }
//         return {
//           'songs': finalSongs,
//           'error': '',
//         };
//       } else {
//         return {
//           'songs': List.empty(),
//           'error': res.body,
//         };
//       }
//     } catch (e) {
//       Logger.root.severe('Error in fetchSongSearchResults: $e');
//       return {
//         'songs': List.empty(),
//         'error': e,
//       };
//     }
//   }

//   Future<List<Map<String, dynamic>>> fetchSearchResults(
//     String searchQuery,
//   ) async {
//     final Map<String, List> result = {};
//     final Map<int, String> position = {};
//     List searchedSongList = [];
//     List searchedAlbumList = [];
//     List searchedPlaylistList = [];
//     List searchedArtistList = [];
//     List searchedTopQueryList = [];

//     final String params =
//         '__call=autocomplete.get&cc=in&includeMetaTags=1&query=$searchQuery';

//     final res = await getResponse(params, usev4: false);
//     if (res.statusCode == 200) {
//       final getMain = json.decode(res.body);
//       final List albumResponseList = getMain['albums']['data'] as List;
//       position[getMain['albums']['position'] as int] = 'Albums';

//       final List playlistResponseList = getMain['playlists']['data'] as List;
//       position[getMain['playlists']['position'] as int] = 'Playlists';

//       final List artistResponseList = getMain['artists']['data'] as List;
//       position[getMain['artists']['position'] as int] = 'Artists';
//       final List topQuery = getMain['topquery']['data'] as List;

//       searchedAlbumList =
//           await FormatResponse.formatAlbumResponse(albumResponseList, 'album');
//       if (searchedAlbumList.isNotEmpty) {
//         result['Albums'] = searchedAlbumList;
//       }

//       searchedPlaylistList = await FormatResponse.formatAlbumResponse(
//         playlistResponseList,
//         'playlist',
//       );
//       if (searchedPlaylistList.isNotEmpty) {
//         result['Playlists'] = searchedPlaylistList;
//       }

//       searchedArtistList = await FormatResponse.formatAlbumResponse(
//         artistResponseList,
//         'artist',
//       );
//       if (searchedArtistList.isNotEmpty) {
//         result['Artists'] = searchedArtistList;
//       }

//       searchedSongList = (await SaavnAPI().fetchSongSearchResults(
//             searchQuery: searchQuery,
//             count: 50,
//           ))['songs'] as List? ??
//           [];
//       if (searchedSongList.isNotEmpty) {
//         result['Songs'] = searchedSongList;
//       }

//       if (topQuery.isNotEmpty &&
//           (topQuery[0]['type'] != 'playlist' ||
//               topQuery[0]['type'] == 'artist' ||
//               topQuery[0]['type'] == 'album')) {
//         position[getMain['topquery']['position'] as int] = 'Top Result';
//         position[getMain['songs']['position'] as int] = 'Songs';

//         switch (topQuery[0]['type'] as String) {
//           case 'artist':
//             searchedTopQueryList =
//                 await FormatResponse.formatAlbumResponse(topQuery, 'artist');
//           case 'album':
//             searchedTopQueryList =
//                 await FormatResponse.formatAlbumResponse(topQuery, 'album');
//           case 'playlist':
//             searchedTopQueryList =
//                 await FormatResponse.formatAlbumResponse(topQuery, 'playlist');
//           default:
//             break;
//         }
//         if (searchedTopQueryList.isNotEmpty) {
//           result['Top Result'] = searchedTopQueryList;
//         }
//       } else {
//         if (topQuery.isNotEmpty && topQuery[0]['type'] == 'song') {
//           position[getMain['topquery']['position'] as int] = 'Songs';
//         } else {
//           position[getMain['songs']['position'] as int] = 'Songs';
//         }
//       }
//     }

//     final sortedKeys = position.entries.toList()
//       ..sort((a, b) => a.key.compareTo(b.key));

//     final List<Map<String, dynamic>> finalList = [];
//     for (final entry in sortedKeys) {
//       if (result.containsKey(entry.value)) {
//         finalList.add({'title': entry.value, 'items': result[entry.value]});
//       }
//     }
//     return finalList;
//   }

//   Future<List<Map>> fetchAlbums({
//     required String searchQuery,
//     required String type,
//     int count = 20,
//     int page = 1,
//   }) async {
//     String? params;
//     if (type == 'playlist') {
//       params =
//           'p=$page&q=$searchQuery&n=$count&${endpoints["playlistResults"]}';
//     }
//     if (type == 'album') {
//       params = 'p=$page&q=$searchQuery&n=$count&${endpoints["albumResults"]}';
//     }
//     if (type == 'artist') {
//       params = 'p=$page&q=$searchQuery&n=$count&${endpoints["artistResults"]}';
//     }

//     final res = await getResponse(params!);
//     if (res.statusCode == 200) {
//       final getMain = json.decode(res.body);
//       final List responseList = getMain['results'] as List;
//       return FormatResponse.formatAlbumResponse(responseList, type);
//     }
//     return List.empty();
//   }

//   Future<Map> fetchAlbumSongs(String albumId) async {
//     final String params = '${endpoints['albumDetails']}&cc=in&albumid=$albumId';
//     try {
//       final res = await getResponse(params);
//       if (res.statusCode == 200) {
//         final getMain = json.decode(res.body);
//         if (getMain['list'] != '') {
//           final List responseList = getMain['list'] as List;
//           return {
//             'songs':
//                 await FormatResponse.formatSongsResponse(responseList, 'album'),
//             'error': '',
//           };
//         }
//       }
//       Logger.root.severe('Songs not found in fetchAlbumSongs: ${res.body}');
//       return {
//         'songs': List.empty(),
//         'error': '',
//       };
//     } catch (e) {
//       Logger.root.severe('Error in fetchAlbumSongs: $e');
//       return {
//         'songs': List.empty(),
//         'error': e,
//       };
//     }
//   }

//   Future<Map<String, List>> fetchArtistSongs({
//     required String artistToken,
//     String category = '',
//     String sortOrder = '',
//   }) async {
//     final Map<String, List> data = {};
//     final String params =
//         '${endpoints["fromToken"]}&type=artist&p=&n_song=50&n_album=50&sub_type=&category=$category&sort_order=$sortOrder&includeMetaTags=0&token=$artistToken';
//     final res = await getResponse(params);
//     if (res.statusCode == 200) {
//       final getMain = json.decode(res.body) as Map;
//       final List topSongsResponseList = getMain['topSongs'] as List;
//       final List latestReleaseResponseList = getMain['latest_release'] as List;
//       final List topAlbumsResponseList = getMain['topAlbums'] as List;
//       final List singlesResponseList = getMain['singles'] as List;
//       final List dedicatedResponseList =
//           getMain['dedicated_artist_playlist'] as List;
//       final List featuredResponseList =
//           getMain['featured_artist_playlist'] as List;
//       final List similarArtistsResponseList = getMain['similarArtists'] as List;

//       final List topSongsSearchedList =
//           await FormatResponse.formatSongsResponse(
//         topSongsResponseList,
//         'song',
//       );
//       if (topSongsSearchedList.isNotEmpty) {
//         data[getMain['modules']?['topSongs']?['title']?.toString() ??
//             'Top Songs'] = topSongsSearchedList;
//       }

//       final List latestReleaseSearchedList =
//           await FormatResponse.formatArtistTopAlbumsResponse(
//         latestReleaseResponseList,
//       );
//       if (latestReleaseSearchedList.isNotEmpty) {
//         data[getMain['modules']?['latest_release']?['title']?.toString() ??
//             'Latest Releases'] = latestReleaseSearchedList;
//       }

//       final List topAlbumsSearchedList =
//           await FormatResponse.formatArtistTopAlbumsResponse(
//         topAlbumsResponseList,
//       );
//       if (topAlbumsSearchedList.isNotEmpty) {
//         data[getMain['modules']?['topAlbums']?['title']?.toString() ??
//             'Top Albums'] = topAlbumsSearchedList;
//       }

//       final List singlesSearchedList =
//           await FormatResponse.formatArtistTopAlbumsResponse(
//         singlesResponseList,
//       );
//       if (singlesSearchedList.isNotEmpty) {
//         data[getMain['modules']?['singles']?['title']?.toString() ??
//             'Singles'] = singlesSearchedList;
//       }

//       final List dedicatedSearchedList =
//           await FormatResponse.formatArtistTopAlbumsResponse(
//         dedicatedResponseList,
//       );
//       if (dedicatedSearchedList.isNotEmpty) {
//         data[getMain['modules']?['dedicated_artist_playlist']?['title']
//                 ?.toString() ??
//             'Dedicated Playlists'] = dedicatedSearchedList;
//       }

//       final List featuredSearchedList =
//           await FormatResponse.formatArtistTopAlbumsResponse(
//         featuredResponseList,
//       );
//       if (featuredSearchedList.isNotEmpty) {
//         data[getMain['modules']?['featured_artist_playlist']?['title']
//                 ?.toString() ??
//             'Featured Playlists'] = featuredSearchedList;
//       }

//       final List similarArtistsSearchedList =
//           await FormatResponse.formatSimilarArtistsResponse(
//         similarArtistsResponseList,
//       );
//       if (similarArtistsSearchedList.isNotEmpty) {
//         data[getMain['modules']?['similarArtists']?['title']?.toString() ??
//             'Similar Artists'] = similarArtistsSearchedList;
//       }
//     }
//     return data;
//   }

//   Future<Map> fetchPlaylistSongs(String playlistId) async {
//     final String params =
//         '${endpoints["playlistDetails"]}&cc=in&listid=$playlistId';
//     try {
//       final res = await getResponse(params);
//       if (res.statusCode == 200) {
//         final getMain = json.decode(res.body);
//         if (getMain['list'] != '') {
//           final List responseList = getMain['list'] as List;
//           return {
//             'songs': await FormatResponse.formatSongsResponse(
//               responseList,
//               'playlist',
//             ),
//             'error': '',
//           };
//         }
//         return {
//           'songs': List.empty(),
//           'error': '',
//         };
//       } else {
//         return {
//           'songs': List.empty(),
//           'error': res.body,
//         };
//       }
//     } catch (e) {
//       Logger.root.severe('Error in fetchPlaylistSongs: $e');
//       return {
//         'songs': List.empty(),
//         'error': e,
//       };
//     }
//   }

//   Future<Map> fetchSongDetails(String songId) async {
//     final String params = 'pids=$songId&${endpoints["songDetails"]}';
//     try {
//       final res = await getResponse(params);
//       if (res.statusCode == 200) {
//         final Map data = json.decode(res.body) as Map;
//         return await FormatResponse.formatSingleSongResponse(
//           data['songs'][0] as Map,
//         );
//       }
//     } catch (e) {
//       Logger.root.severe('Error in fetchSongDetails: $e');
//     }
//     return {};
//   }
// }
// Coded by Naseer Ahmed

import 'dart:convert';
import 'dart:io';

import 'package:blackhole/Helpers/format.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';

class SaavnAPI {
  List preferredLanguages = Hive.box('settings')
      .get('preferredLanguage', defaultValue: ['Hindi']) as List;
  Map<String, String> headers = {};
  String baseUrl = 'www.jiosaavn.com';
  String apiStr = '/api.php?_format=json&_marker=0&api_version=4&ctx=web6dot0';
  Box settingsBox = Hive.box('settings');
  Map<String, String> endpoints = {
    'homeData': '__call=webapi.getLaunchData',
    'topSearches': '__call=content.getTopSearches',
    'fromToken': '__call=webapi.get',
    'featuredRadio': '__call=webradio.createFeaturedStation',
    'artistRadio': '__call=webradio.createArtistStation',
    'entityRadio': '__call=webradio.createEntityStation',
    'radioSongs': '__call=webradio.getSong',
    'songDetails': '__call=song.getDetails',
    'playlistDetails': '__call=playlist.getDetails',
    'albumDetails': '__call=content.getAlbumDetails',
    'getResults': '__call=search.getResults',
    'albumResults': '__call=search.getAlbumResults',
    'artistResults': '__call=search.getArtistResults',
    'playlistResults': '__call=search.getPlaylistResults',
    'getReco': '__call=reco.getreco',
    'getAlbumReco': '__call=reco.getAlbumReco', // still not used
    'artistOtherTopSongs':
        '__call=search.artistOtherTopSongs', // still not used
  };

  Future<Response> getResponse(
    String params, {
    bool usev4 = true,
    bool useProxy = true,
  }) async {
    // Start debugging
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🚀 STARTING SAAVN API CALL');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    print('📋 Parameters received: $params');
    print('⚙️  Configuration: usev4=$usev4, useProxy=$useProxy');

    Uri url;

    // Step 1: URL Construction
    print('\n🔗 STEP 1: Constructing URL...');
    if (!usev4) {
      print('   Using API v3 (removing v4 parameter)');
      final cleanedParams = '$apiStr&$params'.replaceAll('&api_version=4', '');
      url = Uri.https(baseUrl, cleanedParams);
      print('   V3 URL constructed');
    } else {
      print('   Using API v4');
      url = Uri.https(baseUrl, '$apiStr&$params');
      print('   V4 URL constructed');
    }
    print('   📍 Final URL: $url');

    // Step 2: Headers Preparation
    print('\n📝 STEP 2: Preparing headers...');

    // Process preferred languages
    print('   Processing preferred languages...');
    final originalLanguages = List.from(preferredLanguages);
    preferredLanguages =
        preferredLanguages.map((lang) => lang.toLowerCase()).toList();
    print('   Original: $originalLanguages');
    print('   Processed: $preferredLanguages');

    final String languageHeader = 'L=${preferredLanguages.join('%2C')}';
    print('   Language Header: $languageHeader');

    headers = {'cookie': languageHeader, 'Accept': '*/*'};
    print('   Base Headers: $headers');

    // Step 3: Proxy Configuration Check
    print('\n🌐 STEP 3: Checking proxy configuration...');
    print('   Requested useProxy: $useProxy');
    final settingsUseProxy =
        settingsBox.get('useProxy', defaultValue: false) as bool;
    print('   Settings useProxy: $settingsUseProxy');

    bool shouldUseProxy = useProxy && settingsUseProxy;
    print('   Should use proxy: $shouldUseProxy');

    // Make the actual request
    print('\n📤 STEP 4: Making HTTP request...');

    if (shouldUseProxy) {
      print('   🔄 Using PROXY configuration');
      final String proxyIP =
          settingsBox.get('proxyIp', defaultValue: '103.47.67.134').toString();
      print('   Proxy IP from settings: $proxyIP');

      final proxyHeaders = Map<String, String>.from(headers);
      proxyHeaders['X-FORWARDED-FOR'] = proxyIP;
      print('   Final headers with proxy: $proxyHeaders');
      print('   Final URL with proxy: $url');
      print('   📤 Sending proxy request...');

      try {
        final response = await get(url, headers: proxyHeaders);
        print('   ✅ Proxy request completed!');
        print('   📊 Status Code: ${response.statusCode}');
        print('   📦 Response Size: ${response.body.length} bytes');

        // Debug response content
        if (response.statusCode != 200) {
          print('   ⚠️  Non-200 status code!');
          print('   Response body (first 500 chars):');
          if (response.body.length > 500) {
            print('   ${response.body.substring(0, 500)}...');
          } else {
            print('   ${response.body}');
          }
        } else {
          // Try to parse and show song count for successful responses
          try {
            final jsonData = jsonDecode(response.body);
            if (jsonData is Map) {
              if (jsonData.containsKey('songs') && jsonData['songs'] is List) {
                final songs = jsonData['songs'] as List;
                print('   🎵 Found ${songs.length} songs in response');
              } else if (jsonData.containsKey('data') &&
                  jsonData['data'] is List) {
                final data = jsonData['data'] as List;
                print('   📁 Found ${data.length} items in data');
              }
              if (jsonData.containsKey('status')) {
                print('   📊 API Status: ${jsonData['status']}');
              }
            }
          } catch (e) {
            print('   ℹ️  Could not parse JSON response (might be expected)');
          }
        }

        print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ PROXY CALL COMPLETED - Status: ${response.statusCode}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return response;
      } catch (error, stackTrace) {
        print('   ❌ Proxy request failed with error!');
        print('   Error: $error');
        print('   StackTrace: $stackTrace');

        print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ PROXY CALL FAILED - Returning error response');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return Response(
          {
            'status': 'failure',
            'error': error.toString(),
            'type': error.runtimeType.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          }.toString(),
          404,
        );
      }
    } else {
      print('   🌐 Using DIRECT connection (no proxy)');
      print('   Final headers: $headers');
      print('   Final URL: $url');
      print('   📤 Sending direct request...');

      try {
        final response = await get(url, headers: headers);
        print('   ✅ Direct request completed!');
        print('   📊 Status Code: ${response.statusCode}');
        print('   📦 Response Size: ${response.body.length} bytes');

        // Debug response content
        if (response.statusCode != 200) {
          print('   ⚠️  Non-200 status code!');
          print('   Response body (first 500 chars):');
          if (response.body.length > 500) {
            print('   ${response.body.substring(0, 500)}...');
          } else {
            print('   ${response.body}');
          }
        } else {
          // Try to parse and show song count for successful responses
          try {
            final jsonData = jsonDecode(response.body);
            if (jsonData is Map) {
              if (jsonData.containsKey('songs') && jsonData['songs'] is List) {
                final songs = jsonData['songs'] as List;
                print('   🎵 Found ${songs.length} songs in response');
              } else if (jsonData.containsKey('data') &&
                  jsonData['data'] is List) {
                final data = jsonData['data'] as List;
                print('   📁 Found ${data.length} items in data');
              }
              if (jsonData.containsKey('status')) {
                print('   📊 API Status: ${jsonData['status']}');
              }
            }
          } catch (e) {
            print('   ℹ️  Could not parse JSON response (might be expected)');
          }
        }

        print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ DIRECT CALL COMPLETED - Status: ${response.statusCode}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return response;
      } catch (error, stackTrace) {
        print('   ❌ Direct request failed with error!');
        print('   Error: $error');
        print('   StackTrace: $stackTrace');

        print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ DIRECT CALL FAILED - Returning error response');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return Response(
          {
            'status': 'failure',
            'error': error.toString(),
            'type': error.runtimeType.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          }.toString(),
          404,
        );
      }
    }
  }

  Future<Map> fetchHomePageData() async {
    Map result = {};
    try {
      final res = await getResponse(endpoints['homeData']!, useProxy: false);
      if (res.statusCode == 200) {
        final Map data = json.decode(res.body) as Map;
        result = await FormatResponse.formatHomePageData(data);
      }
    } catch (e) {
      Logger.root.severe('Error in fetchHomePageData: $e');
    }
    return result;
  }

  Future<Map> getSongFromToken(
    String token,
    String type, {
    int n = 10,
    int p = 1,
  }) async {
    if (n == -1) {
      final String params =
          "token=$token&type=$type&n=5&p=$p&${endpoints['fromToken']}";
      try {
        final res = await getResponse(params);
        if (res.statusCode == 200) {
          final Map getMain = json.decode(res.body) as Map;
          final String count = getMain['list_count'].toString();
          final String params2 =
              "token=$token&type=$type&n=$count&p=$p&${endpoints['fromToken']}";
          final res2 = await getResponse(params2);
          if (res2.statusCode == 200) {
            final Map getMain2 = json.decode(res2.body) as Map;
            final List responseList = ((type == 'album' || type == 'playlist')
                ? getMain2['list']
                : getMain2['songs']) as List;
            final result = {
              'songs':
                  await FormatResponse.formatSongsResponse(responseList, type),
              'title': getMain2['title'],
            };
            return result;
          } else {
            Logger.root.severe(
              'getSongFromToken with -1 got res2 with ${res2.statusCode}: ${res2.body}',
            );
          }
        } else {
          Logger.root.severe(
            'getSongFromToken with -1 got ${res.statusCode}: ${res.body}',
          );
        }
      } catch (e) {
        Logger.root.severe('Error in getSongFromToken with -1: $e');
      }
      return {'songs': List.empty()};
    } else {
      final String params =
          "token=$token&type=$type&n=$n&p=$p&${endpoints['fromToken']}";
      try {
        final res = await getResponse(params);
        if (res.statusCode == 200) {
          final Map getMain = json.decode(res.body) as Map;
          if (getMain['status'] == 'failure') {
            Logger.root.severe('Error in getSongFromToken response: $getMain');
            return {'songs': List.empty()};
          }
          if (type == 'album' || type == 'playlist') {
            return getMain;
          }
          if (type == 'show') {
            final List responseList = getMain['episodes'] as List;
            return {
              'songs':
                  await FormatResponse.formatSongsResponse(responseList, type),
            };
          }
          if (type == 'mix') {
            final List responseList = getMain['list'] as List;
            return {
              'songs':
                  await FormatResponse.formatSongsResponse(responseList, type),
            };
          }
          final List responseList = getMain['songs'] as List;
          return {
            'songs':
                await FormatResponse.formatSongsResponse(responseList, type),
            'title': getMain['title'],
          };
        }
      } catch (e) {
        Logger.root.severe('Error in getSongFromToken: $e');
      }
      return {'songs': List.empty()};
    }
  }

  Future<List> getReco(String pid) async {
    print('Getting recommendations for pid: $pid');
    final String params = "${endpoints['getReco']}&pid=$pid";
    print('Params for getReco: $params');
    final res = await getResponse(params);
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      print('getReco response body: ${res.statusCode}, ${res.body}');
      final List getMain = json.decode(res.body) as List;
      return FormatResponse.formatSongsResponse(getMain, 'song');
    } else {
      Logger.root.severe(
        'Error in getReco returned status: ${res.statusCode}, response: ${res.body}',
      );
    }
    return List.empty();
  }

  Future<String?> createRadio({
    required List<String> names,
    required String stationType,
    String? language,
  }) async {
    String? params;
    if (stationType == 'featured') {
      params =
          "name=${names[0]}&language=$language&${endpoints['featuredRadio']}";
    }
    if (stationType == 'artist') {
      params =
          "name=${names[0]}&query=${names[0]}&language=$language&${endpoints['artistRadio']}";
    }
    if (stationType == 'entity') {
      params =
          'entity_id=${names.map((e) => '"$e"').toList()}&entity_type=queue&${endpoints["entityRadio"]}';
    }

    final res = await getResponse(params!);
    if (res.statusCode == 200) {
      final Map getMain = json.decode(res.body) as Map;
      return getMain['stationid']?.toString();
    }
    return null;
  }

  Future<List> getRadioSongs({
    required String stationId,
    int count = 20,
    int next = 1,
  }) async {
    if (count > 0) {
      final String params =
          "stationid=$stationId&k=$count&next=$next&${endpoints['radioSongs']}";
      final res = await getResponse(params);
      if (res.statusCode == 200) {
        final Map getMain = json.decode(res.body) as Map;
        final List responseList = [];
        if (getMain['error'] != null && getMain['error'] != '') {
          return [];
        }
        for (int i = 0; i < count; i++) {
          responseList.add(getMain[i.toString()]['song']);
        }
        return FormatResponse.formatSongsResponse(responseList, 'song');
      }
      return [];
    }
    return [];
  }

  Future<List<String>> getTopSearches() async {
    try {
      final res = await getResponse(endpoints['topSearches']!);
      if (res.statusCode == 200) {
        final List getMain = json.decode(res.body) as List;
        return getMain.map((element) {
          return element['title'].toString();
        }).toList();
      }
    } catch (e) {
      Logger.root.severe('Error in getTopSearches: $e');
    }
    return List.empty();
  }

  Future<Map> fetchSongSearchResults({
    required String searchQuery,
    int count = 20,
    int page = 1,
  }) async {
    final String params =
        'p=$page&q=$searchQuery&n=$count&${endpoints["getResults"]}';
    try {
      final res = await getResponse(params);
      if (res.statusCode == 200) {
        final Map getMain = json.decode(res.body) as Map;
        final List responseList = getMain['results'] as List;
        final finalSongs =
            await FormatResponse.formatSongsResponse(responseList, 'song');
        if (finalSongs.length > count) {
          finalSongs.removeRange(count, finalSongs.length);
        }
        return {
          'songs': finalSongs,
          'error': '',
        };
      } else {
        return {
          'songs': List.empty(),
          'error': res.body,
        };
      }
    } catch (e) {
      Logger.root.severe('Error in fetchSongSearchResults: $e');
      return {
        'songs': List.empty(),
        'error': e,
      };
    }
  }

  Future<List<Map<String, dynamic>>> fetchSearchResults(
    String searchQuery,
  ) async {
    final Map<String, List> result = {};
    final Map<int, String> position = {};
    List searchedSongList = [];
    List searchedAlbumList = [];
    List searchedPlaylistList = [];
    List searchedArtistList = [];
    List searchedTopQueryList = [];

    final String params =
        '__call=autocomplete.get&cc=in&includeMetaTags=1&query=$searchQuery';

    final res = await getResponse(params, usev4: false);
    if (res.statusCode == 200) {
      final getMain = json.decode(res.body);
      final List albumResponseList = getMain['albums']['data'] as List;
      position[getMain['albums']['position'] as int] = 'Albums';

      final List playlistResponseList = getMain['playlists']['data'] as List;
      position[getMain['playlists']['position'] as int] = 'Playlists';

      final List artistResponseList = getMain['artists']['data'] as List;
      position[getMain['artists']['position'] as int] = 'Artists';
      final List topQuery = getMain['topquery']['data'] as List;

      searchedAlbumList =
          await FormatResponse.formatAlbumResponse(albumResponseList, 'album');
      if (searchedAlbumList.isNotEmpty) {
        result['Albums'] = searchedAlbumList;
      }

      searchedPlaylistList = await FormatResponse.formatAlbumResponse(
        playlistResponseList,
        'playlist',
      );
      if (searchedPlaylistList.isNotEmpty) {
        result['Playlists'] = searchedPlaylistList;
      }

      searchedArtistList = await FormatResponse.formatAlbumResponse(
        artistResponseList,
        'artist',
      );
      if (searchedArtistList.isNotEmpty) {
        result['Artists'] = searchedArtistList;
      }

      searchedSongList = (await SaavnAPI().fetchSongSearchResults(
            searchQuery: searchQuery,
            count: 50,
          ))['songs'] as List? ??
          [];
      if (searchedSongList.isNotEmpty) {
        result['Songs'] = searchedSongList;
      }

      if (topQuery.isNotEmpty &&
          (topQuery[0]['type'] != 'playlist' ||
              topQuery[0]['type'] == 'artist' ||
              topQuery[0]['type'] == 'album')) {
        position[getMain['topquery']['position'] as int] = 'Top Result';
        position[getMain['songs']['position'] as int] = 'Songs';

        switch (topQuery[0]['type'] as String) {
          case 'artist':
            searchedTopQueryList =
                await FormatResponse.formatAlbumResponse(topQuery, 'artist');
          case 'album':
            searchedTopQueryList =
                await FormatResponse.formatAlbumResponse(topQuery, 'album');
          case 'playlist':
            searchedTopQueryList =
                await FormatResponse.formatAlbumResponse(topQuery, 'playlist');
          default:
            break;
        }
        if (searchedTopQueryList.isNotEmpty) {
          result['Top Result'] = searchedTopQueryList;
        }
      } else {
        if (topQuery.isNotEmpty && topQuery[0]['type'] == 'song') {
          position[getMain['topquery']['position'] as int] = 'Songs';
        } else {
          position[getMain['songs']['position'] as int] = 'Songs';
        }
      }
    }

    final sortedKeys = position.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final List<Map<String, dynamic>> finalList = [];
    for (final entry in sortedKeys) {
      if (result.containsKey(entry.value)) {
        finalList.add({'title': entry.value, 'items': result[entry.value]});
      }
    }
    return finalList;
  }

  Future<List<Map>> fetchAlbums({
    required String searchQuery,
    required String type,
    int count = 20,
    int page = 1,
  }) async {
    String? params;
    if (type == 'playlist') {
      params =
          'p=$page&q=$searchQuery&n=$count&${endpoints["playlistResults"]}';
    }
    if (type == 'album') {
      params = 'p=$page&q=$searchQuery&n=$count&${endpoints["albumResults"]}';
    }
    if (type == 'artist') {
      params = 'p=$page&q=$searchQuery&n=$count&${endpoints["artistResults"]}';
    }

    final res = await getResponse(params!);
    if (res.statusCode == 200) {
      final getMain = json.decode(res.body);
      final List responseList = getMain['results'] as List;
      return FormatResponse.formatAlbumResponse(responseList, type);
    }
    return List.empty();
  }

  Future<Map> fetchAlbumSongs(String albumId) async {
    final String params = '${endpoints['albumDetails']}&cc=in&albumid=$albumId';
    try {
      final res = await getResponse(params);
      if (res.statusCode == 200) {
        final getMain = json.decode(res.body);
        if (getMain['list'] != '') {
          final List responseList = getMain['list'] as List;
          return {
            'songs':
                await FormatResponse.formatSongsResponse(responseList, 'album'),
            'error': '',
          };
        }
      }
      Logger.root.severe('Songs not found in fetchAlbumSongs: ${res.body}');
      return {
        'songs': List.empty(),
        'error': '',
      };
    } catch (e) {
      Logger.root.severe('Error in fetchAlbumSongs: $e');
      return {
        'songs': List.empty(),
        'error': e,
      };
    }
  }

  Future<Map<String, List>> fetchArtistSongs({
    required String artistToken,
    String category = '',
    String sortOrder = '',
  }) async {
    final Map<String, List> data = {};
    final String params =
        '${endpoints["fromToken"]}&type=artist&p=&n_song=50&n_album=50&sub_type=&category=$category&sort_order=$sortOrder&includeMetaTags=0&token=$artistToken';
    final res = await getResponse(params);
    if (res.statusCode == 200) {
      final getMain = json.decode(res.body) as Map;
      final List topSongsResponseList = getMain['topSongs'] as List;
      final List latestReleaseResponseList = getMain['latest_release'] as List;
      final List topAlbumsResponseList = getMain['topAlbums'] as List;
      final List singlesResponseList = getMain['singles'] as List;
      final List dedicatedResponseList =
          getMain['dedicated_artist_playlist'] as List;
      final List featuredResponseList =
          getMain['featured_artist_playlist'] as List;
      final List similarArtistsResponseList = getMain['similarArtists'] as List;

      final List topSongsSearchedList =
          await FormatResponse.formatSongsResponse(
        topSongsResponseList,
        'song',
      );
      if (topSongsSearchedList.isNotEmpty) {
        data[getMain['modules']?['topSongs']?['title']?.toString() ??
            'Top Songs'] = topSongsSearchedList;
      }

      final List latestReleaseSearchedList =
          await FormatResponse.formatArtistTopAlbumsResponse(
        latestReleaseResponseList,
      );
      if (latestReleaseSearchedList.isNotEmpty) {
        data[getMain['modules']?['latest_release']?['title']?.toString() ??
            'Latest Releases'] = latestReleaseSearchedList;
      }

      final List topAlbumsSearchedList =
          await FormatResponse.formatArtistTopAlbumsResponse(
        topAlbumsResponseList,
      );
      if (topAlbumsSearchedList.isNotEmpty) {
        data[getMain['modules']?['topAlbums']?['title']?.toString() ??
            'Top Albums'] = topAlbumsSearchedList;
      }

      final List singlesSearchedList =
          await FormatResponse.formatArtistTopAlbumsResponse(
        singlesResponseList,
      );
      if (singlesSearchedList.isNotEmpty) {
        data[getMain['modules']?['singles']?['title']?.toString() ??
            'Singles'] = singlesSearchedList;
      }

      final List dedicatedSearchedList =
          await FormatResponse.formatArtistTopAlbumsResponse(
        dedicatedResponseList,
      );
      if (dedicatedSearchedList.isNotEmpty) {
        data[getMain['modules']?['dedicated_artist_playlist']?['title']
                ?.toString() ??
            'Dedicated Playlists'] = dedicatedSearchedList;
      }

      final List featuredSearchedList =
          await FormatResponse.formatArtistTopAlbumsResponse(
        featuredResponseList,
      );
      if (featuredSearchedList.isNotEmpty) {
        data[getMain['modules']?['featured_artist_playlist']?['title']
                ?.toString() ??
            'Featured Playlists'] = featuredSearchedList;
      }

      final List similarArtistsSearchedList =
          await FormatResponse.formatSimilarArtistsResponse(
        similarArtistsResponseList,
      );
      if (similarArtistsSearchedList.isNotEmpty) {
        data[getMain['modules']?['similarArtists']?['title']?.toString() ??
            'Similar Artists'] = similarArtistsSearchedList;
      }
    }
    return data;
  }

  Future<Map> fetchPlaylistSongs(String playlistId) async {
    final String params =
        '${endpoints["playlistDetails"]}&cc=in&listid=$playlistId';
    try {
      final res = await getResponse(params);
      if (res.statusCode == 200) {
        final getMain = json.decode(res.body);
        if (getMain['list'] != '') {
          final List responseList = getMain['list'] as List;
          return {
            'songs': await FormatResponse.formatSongsResponse(
              responseList,
              'playlist',
            ),
            'error': '',
          };
        }
        return {
          'songs': List.empty(),
          'error': '',
        };
      } else {
        return {
          'songs': List.empty(),
          'error': res.body,
        };
      }
    } catch (e) {
      Logger.root.severe('Error in fetchPlaylistSongs: $e');
      return {
        'songs': List.empty(),
        'error': e,
      };
    }
  }

  Future<Map> fetchSongDetails(String songId) async {
    final String params = 'pids=$songId&${endpoints["songDetails"]}';
    try {
      final res = await getResponse(params);
      if (res.statusCode == 200) {
        final Map data = json.decode(res.body) as Map;
        return await FormatResponse.formatSingleSongResponse(
          data['songs'][0] as Map,
        );
      }
    } catch (e) {
      Logger.root.severe('Error in fetchSongDetails: $e');
    }
    return {};
  }
}
