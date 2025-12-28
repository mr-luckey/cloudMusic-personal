// Coded by Naseer Ahmed

import 'dart:io';

import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/github.dart';
import 'package:blackhole/Helpers/update.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/localization/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String? appVersion;

  @override
  void initState() {
    main();
    super.initState();
  }

  Future<void> main() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
    setState(
      () {},
    );
  }

  @override
  Widget build(BuildContext context) {
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
                .about,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          iconTheme: IconThemeData(
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    10.0,
                    10.0,
                    10.0,
                    10.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .version,
                        ),
                        subtitle: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .versionSub,
                        ),
                        onTap: () {
                          ShowSnackBar().showSnackBar(
                            context,
                            AppLocalizations.of(
                              context,
                            )!
                                .checkingUpdate,
                            noAction: true,
                          );

                          // GitHub.getLatestVersion().then(
                          //   (String latestVersion) async {
                          //     if (compareVersion(
                          //       latestVersion,
                          //       appVersion!,
                          //     )) {
                          //       ShowSnackBar().showSnackBar(
                          //         context,
                          //         AppLocalizations.of(context)!.updateAvailable,
                          //         duration: const Duration(seconds: 15),
                          //         action: SnackBarAction(
                          //           textColor:
                          //               Theme.of(context).colorScheme.secondary,
                          //           label: AppLocalizations.of(context)!.update,
                          //           onPressed: () async {
                          //             if (Platform.isAndroid) {
                          //               List? abis = await Hive.box('settings')
                          //                   .get('supportedAbis') as List?;
                          //
                          //               if (abis == null) {
                          //                 final DeviceInfoPlugin deviceInfo =
                          //                     DeviceInfoPlugin();
                          //                 final AndroidDeviceInfo
                          //                     androidDeviceInfo =
                          //                     await deviceInfo.androidInfo;
                          //                 abis =
                          //                     androidDeviceInfo.supportedAbis;
                          //                 await Hive.box('settings')
                          //                     .put('supportedAbis', abis);
                          //               }
                          //               if (abis.contains('arm64')) {
                          //               } else if (abis.contains('armeabi')) {}
                          //             }
                          //
                          //             /// The above code is using the Dart programming language.
                          //             Navigator.pop(context);
                          //           },
                          //         ),
                          //       );
                          //     } else {
                          //       ShowSnackBar().showSnackBar(
                          //         context,
                          //         AppLocalizations.of(
                          //           context,
                          //         )!
                          //             .latest,
                          //       );
                          //     }
                          //   },
                          // );
                        },
                        trailing: Text(
                          'v$appVersion',
                          style: const TextStyle(fontSize: 12),
                        ),
                        dense: true,
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .shareApp,
                        ),
                        subtitle: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .shareAppSub,
                        ),
                        onTap: () {
                          Share.share(
                            '${AppLocalizations.of(
                              context,
                            )!.shareAppText}: ', ////TODO: Add the link to the app
                          );
                        },
                        dense: true,
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .likedWork,
                        ),
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: <Widget>[
                  Spacer(),
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(5, 30, 5, 20),
                      child: Center(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
