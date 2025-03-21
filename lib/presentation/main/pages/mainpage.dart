import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunezmusic/core/configs/assets/app_vectors.dart';
import 'package:tunezmusic/core/configs/bloc/navigation_bloc.dart';
import 'package:tunezmusic/data/services/authManager.dart';
import 'package:tunezmusic/core/configs/theme/app_colors.dart';
import 'package:tunezmusic/presentation/dashboard/pages/dashboard_page.dart';
import 'package:tunezmusic/presentation/library/pages/library.dart';
import 'package:tunezmusic/presentation/library/bloc/artist_follow_bloc.dart';
import 'package:tunezmusic/presentation/library/bloc/artist_follow_event.dart';
import 'package:tunezmusic/presentation/library/bloc/artist_follow_state.dart';
import 'package:tunezmusic/presentation/dashboard/bloc/user_playlist_bloc.dart';
import 'package:tunezmusic/presentation/dashboard/bloc/user_playlist_event.dart';
import 'package:tunezmusic/presentation/dashboard/bloc/user_playlist_state.dart';
import 'package:tunezmusic/presentation/main/widgets/item_bottom_nav.dart';
import 'package:tunezmusic/presentation/premium/pages/premium.dart';
import 'package:tunezmusic/presentation/search/pages/search.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool isLoading = true;
  String? userId;
  final AuthManager auth = AuthManager();

  static final List<Widget> _widgetOptions = [
    const DashboardWidget(),
    const SearchWidget(),
    const LibraryWidget(),
    const PremiumWidget(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('userId');

    if (kDebugMode) print('Saved User ID: $savedUserId');

    if (savedUserId != null && savedUserId.isNotEmpty) {
      final userPlaylistBloc = context.read<HomePlaylistBloc>();
      final artistFollowBloc = context.read<ArtistFollowBloc>();

      userPlaylistBloc.add(FetchHomePlaylistEvent(savedUserId));
      artistFollowBloc.add(FetchArtistFollowEvent(savedUserId));

      await _waitForBlocsToComplete([userPlaylistBloc, artistFollowBloc]);
    }

    if (mounted) {
      setState(() {
        userId = savedUserId;
        isLoading = false;
      });
    }
  }

  Future<void> _waitForBlocsToComplete(List<Bloc> blocs) async {
    final completer = Completer<void>();

    void checkStates() {
      for (final bloc in blocs) {
        if (bloc.state is HomePlaylistLoading ||
            bloc.state is ArtistFollowLoading) {
          return;
        }
        if (bloc.state is HomePlaylistError ||
            bloc.state is ArtistFollowError) {
          _logoutAndRedirect();
          return;
        }
      }
      if (!completer.isCompleted) completer.complete();
    }

    for (final bloc in blocs) {
      bloc.stream.listen((_) => checkStates());
    }

    return completer.future;
  }

  Future<void> _logoutAndRedirect() async {
    if (auth.canLogout() == true) {
      auth.logout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          final navBloc = context.read<NavigationBloc>();
          if (navBloc.state.playlistDetail != null) {
            navBloc.add(ChangeTabEvent(0));
            return false;
          }
          if (navBloc.state.selectedIndex != 0) {
            navBloc.add(ChangeTabEvent(0));
            return false;
          }
          return true;
        },
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: AppColors.darkBackground,
            body: isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : BlocBuilder<NavigationBloc, NavigationState>(
                    builder: (context, state) {
                    return Stack(children: [
                      Positioned.fill(
                          child: state.playlistDetail != null
                              ? state.playlistDetail!
                              : IndexedStack(
                                  index: state.selectedIndex,
                                  children: _widgetOptions,
                                )),
                      Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                              height: 110,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 0, 0, 0),
                                    Color.fromARGB(0, 0, 0, 0),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              alignment: Alignment.bottomCenter,
                              child: BottomNavigationBar(
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                  type: BottomNavigationBarType.fixed,
                                  items: [
                                    {
                                      'index': 0,
                                      'icon': AppVectors.iconHome,
                                      'focusedIcon': AppVectors.iconHomeFocus,
                                      'label': 'Trang chủ',
                                    },
                                    {
                                      'index': 1,
                                      'icon': AppVectors.iconSearch,
                                      'focusedIcon': AppVectors.iconSearchFocus,
                                      'label': 'Tìm kiếm',
                                    },
                                    {
                                      'index': 2,
                                      'icon': AppVectors.iconLibrary,
                                      'focusedIcon':
                                          AppVectors.iconLibraryFocus,
                                      'label': 'Thư viện',
                                    },
                                    {
                                      'index': 3,
                                      'icon': AppVectors.iconPremium,
                                      'focusedIcon':
                                          AppVectors.iconPremiumFocus,
                                      'label': 'Premium',
                                    },
                                  ].map((item) {
                                    return buildBottomNavItem(
                                      index: item['index'] as int,
                                      icon: item['icon'] as String,
                                      focusedIcon:
                                          item['focusedIcon'] as String,
                                      label: item['label'] as String,
                                      selectedIndex: context
                                          .watch<NavigationBloc>()
                                          .state
                                          .selectedIndex,
                                      tappedIndex: null,
                                      onItemTapped: (index) {
                                        context
                                            .read<NavigationBloc>()
                                            .add(ChangeTabEvent(index));
                                      },
                                    );
                                  }).toList(),
                                  currentIndex: state.selectedIndex > 3 ? 0 : state.selectedIndex,
                                  selectedItemColor: Colors.white,
                                  unselectedItemColor: Colors.grey,
                                  selectedLabelStyle:
                                      const TextStyle(fontSize: 11),
                                  unselectedLabelStyle:
                                      const TextStyle(fontSize: 11),
                                  onTap: (index) {
                                    context
                                        .read<NavigationBloc>()
                                        .add(ChangeTabEvent(index));
                                  }))),
                    ]);
                  })));
  }
}
