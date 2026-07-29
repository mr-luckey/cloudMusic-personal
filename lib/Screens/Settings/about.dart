// Coded by Naseer Ahmed

import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/bloc/about_settings/about_settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/localization/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AboutSettingsBloc()..add(const AboutSettingsLoadAppVersion()),
      child: const _AboutPageContent(),
    );
  }
}

class _AboutPageContent extends StatelessWidget {
  const _AboutPageContent();

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
                      BlocBuilder<AboutSettingsBloc, AboutSettingsState>(
                        builder: (context, state) {
                          return ListTile(
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
                            },
                            trailing: Text(
                              'v${state.appVersion}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            dense: true,
                          );
                        },
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
                            )!.shareAppText}: ',
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
