import "dart:async";
import "package:flutter/foundation.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_svg/svg.dart";
import "package:tunezmusic/common/widgets/appBar/app_Bar_intro.dart";
import "package:tunezmusic/common/widgets/button/basic_button.dart";
import "package:tunezmusic/common/widgets/button/basic_outline_button.dart";
import "package:tunezmusic/common/widgets/button/facebook_login_button.dart";
import "package:tunezmusic/common/widgets/button/google_login_button.dart";
import "package:tunezmusic/core/configs/assets/app_images.dart";
import "package:tunezmusic/core/configs/assets/app_vectors.dart";
import "package:tunezmusic/core/configs/theme/app_colors.dart";
import "package:flutter/material.dart";
import "package:tunezmusic/presentation/artistSelection/pages/ArtistSelectionPage.dart";
import "package:tunezmusic/presentation/login/bloc/login_bloc.dart";
import "package:tunezmusic/presentation/login/bloc/login_event.dart";
import "package:tunezmusic/presentation/login/bloc/login_state.dart";
import "package:tunezmusic/presentation/login/pages/login_email.dart";
import "package:tunezmusic/presentation/main/pages/mainpage.dart";
import "package:tunezmusic/presentation/register/pages/register_option.dart";
import "package:tunezmusic/presentation/register/pages/verify_email_noti.dart";

class LoginOptionPage extends StatelessWidget {
  LoginOptionPage({super.key});
  final StreamController<String> phoneNumberStreamController =
      StreamController<String>();
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginGoogleLoadingState ||
            state is LoginFacebookLoadingState) {
          // Hiển thị loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (state is LoginCompletedState) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainPage()),
          );
        }
        if (state is DoVerifiedLoginState) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => VerifyEmail()),
          );
        } else if (state is NewAccountState) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ArtistSelectionPage()),
          );
        } else if (state is LoginErrorState) {
          if (kDebugMode) {
            print(state.message);
          }
          Navigator.of(context, rootNavigator: true).pop();
        } else if (state is LoginGoogleErrorState ||
            state is LoginFacebookErrorState) {
          if (state is LoginGoogleErrorState) {
            if (kDebugMode) {
              print(state.message);
            }
          } else if (state is LoginFacebookErrorState) {
            if (kDebugMode) {
              print(state.message);
            }
          }
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus(); // Hủy focus và đóng bàn phím
          },
          child: Scaffold(
            backgroundColor: AppColors.darkBackground,
            appBar: IntroAppBar(),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 50),
                Align(
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    AppVectors.logoTuneZWhite,
                    width: 100,
                    height: 100,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  child: Text(
                    'Đăng nhập vào TuneZ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 30,
                    ),
                  ),
                ),
                SizedBox(height: 60),
                Container(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        resByEmail(context),
                        SizedBox(height: 10),
                        resByPhone(),
                        SizedBox(height: 10),
                        resByGoogle(context),
                        SizedBox(height: 10),
                        resByFacebook(context),
                        SizedBox(height: 20),
                        Text(
                          "Bạn chưa có tài khoản?",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 20),
                        navigateRegister(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget resByEmail(context) {
    return BasicAppButton(
      title: 'Tiếp tục với email',
      btnColor: AppColors.primary,
      colors: Colors.black,
      icon: AppImages.emailIcon,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (BuildContext context) => LoginPage()),
        );
      },
      textSize: 17,
      height: 52,
    );
  }

  Widget resByPhone() {
    return BasicAppOlButton(
      title: 'Tiếp tục bằng số điện thoại',
      outlineColor: null,
      colors: Colors.white,
      icon: AppImages.phoneIcon,
      onPressed: () {},
      textSize: 17,
      height: 52,
    );
  }

  Widget navigateRegister(context) {
    return BasicAppButton(
      title: 'Đăng ký',
      btnColor: AppColors.darkBackground,
      colors: Colors.white,
      icon: null,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => RegisterOptionPage(),
          ),
        );
      },
      textSize: 14,
      height: 52,
    );
  }
}
