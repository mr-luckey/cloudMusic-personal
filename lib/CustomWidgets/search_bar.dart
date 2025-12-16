// Coded by Naseer Ahmed

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget {
  final Widget body;
  final bool autofocus;
  final bool liveSearch;
  final bool showClose;
  final Widget? leading;
  final String? hintText;
  final TextEditingController controller;
  final Future<List> Function(String)? onQueryChanged;
  final Function()? onQueryCleared;
  final Function(String) onSubmitted;
  final String? selectedFilter;
  final Function(String)? onFilterChanged;
  final bool showFilters;

  const SearchBar({
    super.key,
    this.leading,
    this.hintText,
    this.showClose = true,
    this.autofocus = false,
    this.onQueryChanged,
    this.onQueryCleared,
    this.selectedFilter,
    this.onFilterChanged,
    this.showFilters = false,
    required this.body,
    required this.controller,
    required this.liveSearch,
    required this.onSubmitted,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  String tempQuery = '';
  String query = '';
  final ValueNotifier<bool> hide = ValueNotifier<bool>(true);
  final ValueNotifier<List> suggestionsList = ValueNotifier<List>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  @override
  void dispose() {
    super.dispose();
    hide.dispose();
    suggestionsList.dispose();
    isLoading.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.body,
        ValueListenableBuilder(
          valueListenable: hide,
          builder: (
            BuildContext context,
            bool hidden,
            Widget? child,
          ) {
            return Visibility(
              visible: !hidden,
              child: GestureDetector(
                onTap: () {
                  hide.value = true;
                },
              ),
            );
          },
        ),
        Column(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(
                18.0,
                10.0,
                18.0,
                15.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  10.0,
                ),
              ),
              elevation: 8.0,
              child: SizedBox(
                height: 52.0,
                child: Center(
                  child: TextField(
                    controller: widget.controller,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          width: 1.5,
                          color: Colors.transparent,
                        ),
                      ),
                      fillColor: Theme.of(context).colorScheme.secondary,
                      prefixIcon: widget.leading,
                      suffixIcon: widget.showClose
                          ? ValueListenableBuilder(
                              valueListenable: hide,
                              builder: (
                                BuildContext context,
                                bool hidden,
                                Widget? child,
                              ) {
                                return Visibility(
                                  visible: !hidden,
                                  child: ValueListenableBuilder(
                                    valueListenable: isLoading,
                                    builder: (
                                      BuildContext context,
                                      bool loading,
                                      Widget? child,
                                    ) {
                                      if (loading) {
                                        return const Padding(
                                          padding: EdgeInsets.all(14.0),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      }
                                      return IconButton(
                                        icon: const Icon(Icons.close_rounded),
                                        onPressed: () {
                                          widget.controller.text = '';
                                          hide.value = true;
                                          suggestionsList.value = [];
                                          if (widget.onQueryCleared != null) {
                                            widget.onQueryCleared!.call();
                                          }
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      hintText: widget.hintText,
                    ),
                    autofocus: widget.autofocus,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    onChanged: (val) {
                      tempQuery = val;
                      if (val.trim() == '') {
                        hide.value = true;
                        suggestionsList.value = [];
                        isLoading.value = false;
                        if (widget.onQueryCleared != null) {
                          widget.onQueryCleared!.call();
                        }
                      }
                      if (widget.liveSearch && val.trim() != '') {
                        hide.value = false;
                        isLoading.value = true;
                        Future.delayed(
                          const Duration(
                            milliseconds:
                                800, // Increased from 600ms for better performance
                          ),
                          () async {
                            if (tempQuery == val &&
                                tempQuery.trim() != '' &&
                                tempQuery != query) {
                              query = tempQuery;
                              if (widget.onQueryChanged != null) {
                                try {
                                  suggestionsList.value =
                                      await widget.onQueryChanged!(tempQuery);
                                } finally {
                                  isLoading.value = false;
                                }
                              } else {
                                // No auto-submit - only show suggestions or wait for explicit submit
                                isLoading.value = false;
                              }
                            } else {
                              isLoading.value = false;
                            }
                          },
                        );
                      }
                    },
                    onSubmitted: (submittedQuery) {
                      if (!hide.value) hide.value = true;
                      if (submittedQuery.trim() != '') {
                        query = submittedQuery.trim();
                        widget.onSubmitted(submittedQuery);
                      }
                    },
                  ),
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: hide,
              builder: (
                BuildContext context,
                bool hidden,
                Widget? child,
              ) {
                return Visibility(
                  visible: !hidden,
                  child: ValueListenableBuilder(
                    valueListenable: suggestionsList,
                    builder: (
                      BuildContext context,
                      List suggestedList,
                      Widget? child,
                    ) {
                      return suggestedList.isEmpty
                          ? const SizedBox()
                          : Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 18.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  10.0,
                                ),
                              ),
                              elevation: 8.0,
                              child: SizedBox(
                                height: min(
                                  MediaQuery.sizeOf(context).height / 1.75,
                                  70.0 * suggestedList.length,
                                ),
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                    bottom: 10,
                                  ),
                                  shrinkWrap: true,
                                  itemExtent: 70.0,
                                  itemCount: suggestedList.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      leading:
                                          const Icon(CupertinoIcons.search),
                                      title: Text(
                                        suggestedList[index].toString(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () {
                                        final selectedQuery =
                                            suggestedList[index].toString();
                                        widget.controller.text = selectedQuery;
                                        widget.onSubmitted(selectedQuery);
                                        hide.value = true;
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
