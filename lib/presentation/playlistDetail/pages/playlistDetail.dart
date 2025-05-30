import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:tunezmusic/common/widgets/appBar/app_Bar_playlistDetails.dart';
import 'package:tunezmusic/common/widgets/button/playlist_Detail_button.dart';
import 'package:tunezmusic/common/widgets/loading/loading.dart';
import 'package:tunezmusic/core/configs/assets/app_vectors.dart';
import 'package:tunezmusic/core/configs/bloc/musicManagment/music_bloc.dart';
import 'package:tunezmusic/core/configs/bloc/musicManagment/music_event.dart';
import 'package:tunezmusic/core/configs/bloc/musicManagment/music_state.dart';
import 'package:tunezmusic/core/configs/bloc/navigation_bloc.dart';
import 'package:tunezmusic/core/configs/theme/app_colors.dart';
import 'package:tunezmusic/presentation/playlistDetail/widgets/item_track.dart';

class PlayListDetail extends StatefulWidget {
  final Map playlist;

  const PlayListDetail({super.key, required this.playlist});

  @override
  State<PlayListDetail> createState() => _PlayListDetailState();
}

class _PlayListDetailState extends State<PlayListDetail> {
  ScrollController _scrollController = ScrollController();
  double _opacity = 1.0;
  double _scale = 1;
  final double targetY = 150; // Vị trí bắt đầu làm mờ
  double _blurAmount = 0; // Độ mờ mặc định
  Color _dominantColor = AppColors.grey; // Màu chủ đạo ban đầu
  bool _isLoading = true; // Trạng thái loading

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _extractDominantColor();
    if (kDebugMode) {
      print(widget.playlist);
    }
  }

  void _onScroll() {
    _updateBlurEffect();
    _handleScroll();
  }

  void _updateBlurEffect() {
    double offset = _scrollController.offset;
    double newBlur = (offset > targetY)
        ? ((offset - targetY) / (300 - targetY) * 20).clamp(0, 20)
        : 0;

    if ((_blurAmount - newBlur).abs() > 0.5) {
      setState(() => _blurAmount = newBlur);
    }
  }

  void _handleScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      setState(() {
        _opacity = 0.0;
      });
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      setState(() {
        _opacity = 1.0;
      });
    }
  }

  void _onScale(double scrollOffset) {
    double newScale = 1 - (scrollOffset / 500).clamp(0.0, 0.7);
    setState(() {
      _scale = newScale.clamp(0.1, 1.0);
    });
  }

  Future<void> _extractDominantColor() async {
    final PaletteGenerator paletteGenerator =
        await PaletteGenerator.fromImageProvider(
            NetworkImage(widget.playlist['coverImage']));

    final newColor = paletteGenerator.dominantColor?.color ?? AppColors.grey;
    if (newColor != _dominantColor) {
      setState(() {
        _dominantColor = newColor;
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      });
    }
  }

  String formatDuration(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return "$hours giờ $minutes phút";
    } else {
      return "$minutes phút";
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >= 0) {
            _onScale(scrollInfo.metrics.pixels);
          }
          return true;
        },
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus(); // Bỏ focus khi nhấn ra ngoài
          },
          child: Scaffold(
            body: _isLoading
                ? DotsLoading()
                : Stack(
                    children: [
                      SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          children: [
                            //INTRO PLAYLIST
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    _dominantColor,
                                    AppColors.darkBackground,
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 85),
                                  AnimatedOpacity(
                                    duration: Duration(
                                        milliseconds:
                                            300), // Hiệu ứng mờ trong 300ms
                                    opacity:
                                        _opacity, // Điều chỉnh độ trong suốt
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height:
                                                40, // Chiều cao nhỏ hơn bình thường
                                            child: TextField(
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      14), // Font nhỏ hơn để phù hợp với height
                                              cursorColor: AppColors.primary,
                                              decoration: InputDecoration(
                                                hintText:
                                                    "Tìm trong danh sách phát",
                                                hintStyle: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      14, // Giảm kích thước chữ để phù hợp
                                                ),
                                                prefixIcon: const Icon(
                                                    Icons.search,
                                                    color: Colors.white,
                                                    size: 28),
                                                prefixIconConstraints:
                                                    const BoxConstraints(
                                                  minWidth:
                                                      40, // Giúp icon sát chữ hơn
                                                ),
                                                filled: true,
                                                fillColor: const Color.fromARGB(
                                                    67, 255, 255, 255),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  borderSide: BorderSide.none,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 3,
                                                        horizontal: 0),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        PlaylistAppButton(
                                          onPressed: () {},
                                          title: "Sắp xếp",
                                          colors: Colors.white,
                                          textSize: 14,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 25),
                                  Align(
                                      alignment: Alignment.topCenter,
                                      child: Transform.scale(
                                        scale: _scale,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.5),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: Image.network(
                                              widget.playlist['coverImage'],
                                              width: 220,
                                              height: 220,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      )),
                                  const SizedBox(height: 20),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(widget.playlist['title'],
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.grey,
                                              fontWeight: FontWeight.normal)),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize
                                                .min, // Giới hạn chiều rộng của row
                                            children: [
                                              SvgPicture.asset(
                                                color: _dominantColor,
                                                AppVectors.logoTuneZWhite,
                                                width: 19,
                                                height: 19,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                "Dành cho bạn",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(width: 15),
                                          Expanded(
                                            // Dùng Expanded để tránh tràn ngang
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .report_gmailerrorred_sharp,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 5),
                                                Expanded(
                                                  // Bọc Text trong Expanded để giới hạn chiều rộng
                                                  child: Text(
                                                    "Giới thiệu chung về nội dung đề xuất",
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis, // Hiển thị "..."
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.normal,
                                            color: AppColors.grey,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: "2.308 lượt lưu",
                                            ),
                                            TextSpan(
                                              text: " · ",
                                            ),
                                            TextSpan(
                                              text: formatDuration(widget
                                                  .playlist['totalDuration']),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: AppColors
                                                        .grey, // Màu viền
                                                    width: 2, // Độ dày viền
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8), // Bo tròn viền để khớp với ClipRRect
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: Image.network(
                                                    widget
                                                        .playlist['coverImage'],
                                                    width: 25,
                                                    height: 35,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              IconButton(
                                                  onPressed: () {},
                                                  icon: Icon(
                                                    Icons
                                                        .add_circle_outline_sharp,
                                                    size: 28,
                                                    color: Colors.white,
                                                  )),
                                              IconButton(
                                                  onPressed: () {},
                                                  icon: Icon(
                                                    Icons.downloading_sharp,
                                                    size: 28,
                                                    color: Colors.white,
                                                  )),
                                              IconButton(
                                                  onPressed: () {},
                                                  icon: Icon(
                                                    Icons.more_vert_outlined,
                                                    size: 28,
                                                    color: Colors.white,
                                                  ))
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {},
                                                child: SvgPicture.asset(
                                                  AppVectors.shuffleIcon,
                                                  color: _dominantColor,
                                                  height: 30,
                                                  width: 30,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 20,
                                              ),
                                              BlocBuilder<MusicBloc,
                                                      MusicState>(
                                                  builder: (context, state) {
                                                if (state is MusicLoaded) {
                                                  final currentTrack = widget
                                                      .playlist['tracks']
                                                      .firstWhere(
                                                    (track) =>
                                                        track['_id'] ==
                                                        state.currentMusicId,
                                                    orElse: () => null,
                                                  );

                                                  if (currentTrack != null) {
                                                    return IconButton(
                                                      onPressed: () {
                                                        context
                                                            .read<MusicBloc>()
                                                            .add(
                                                              state.isPlaying
                                                                  ? PauseMusic(
                                                                      musicId: state
                                                                          .currentMusicId)
                                                                  : PlayMusic(
                                                                      musicId: state
                                                                          .currentMusicId),
                                                            );
                                                      },
                                                      icon: Icon(
                                                        state.isPlaying
                                                            ? Icons
                                                                .pause_circle_filled_rounded
                                                            : Icons
                                                                .play_circle_fill_rounded,
                                                        color: _dominantColor,
                                                        size: 60,
                                                      ),
                                                    );
                                                  }
                                                }
                                                return IconButton(
                                                  onPressed: () {
                                                    context
                                                        .read<MusicBloc>()
                                                        .add(UpdatePlaylist(
                                                            allTracks:
                                                                widget.playlist['tracks'].map((t) => t['_id'].toString()).toList()));
                                                    context
                                                        .read<MusicBloc>()
                                                        .add(
                                                            RanDomTrackEvent());
                                                  },
                                                  icon: Icon(
                                                    Icons
                                                        .play_circle_fill_rounded,
                                                    color: _dominantColor,
                                                    size: 60,
                                                  ),
                                                );
                                              })
                                            ],
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            //TRACKS PLAYLIST
                            BlocBuilder<MusicBloc, MusicState>(
                              builder: (context, state) {
                                return Container(
                                  decoration: BoxDecoration(
                                      color: AppColors.darkBackground),
                                  child: Column(
                                    children: widget.playlist['tracks']
                                        .map<Widget>((track) {
                                      return TrackItemWidget(
                                        track: track,
                                        prColor: _dominantColor,
                                        allTracks: widget. playlist['tracks'].map((t) => t['_id'].toString()).toList(),
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 500),
                          ],
                        ),
                      ),
                      PlayListAppBar(
                        title: widget.playlist['title'],
                        blurAmount: _blurAmount,
                        onBackPressed: () {
                          context
                              .read<NavigationBloc>()
                              .add(ClosePlaylistDetailEvent());
                        },
                      ),
                    ],
                  ),
          ),
        ));
  }
}
