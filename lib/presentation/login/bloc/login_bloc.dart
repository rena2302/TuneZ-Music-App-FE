import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunezmusic/data/services/authManager.dart';
import 'package:tunezmusic/core/lib/decode_token.dart';
import 'package:tunezmusic/data/services/api_service.dart';
import 'package:tunezmusic/presentation/login/bloc/login_event.dart';
import 'package:tunezmusic/presentation/login/bloc/login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthManager auth = AuthManager();
  final ApiService apiService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  LoginBloc(this.apiService) : super(LoginInitialState()) {
    on<LoginEmailEvent>(_onLoginByEmail);
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignInWithFacebookEvent>(_onSignInWithFacebook);
    on<ResetLoginStateEvent>(_onResetState);
  }

  Future<void> _onLoginByEmail(
    LoginEmailEvent event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginEmailLoadingState());
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      final idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        await handleLoginResponseByServer(idToken, emit);
      } else {
        emit(LoginErrorState("Không thể lấy ID Token."));
      }
    } catch (e) {
      emit(LoginErrorState("Lỗi khi đăng nhập: ${e.toString()}"));
    }
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginGoogleLoadingState());
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        emit(LoginGoogleErrorState("Người dùng đã hủy đăng nhập"));
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        await handleLoginResponseByServer(idToken, emit);
      } else {
        emit(LoginGoogleErrorState("Không thể lấy ID Token."));
      }
    } catch (error) {
      emit(LoginGoogleErrorState(error.toString()));
    }
  }

  Future<void> _onSignInWithFacebook(
    SignInWithFacebookEvent event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginFacebookLoadingState());
    try {
      final loginResult = await FacebookAuth.instance.login();
      if (loginResult.status != LoginStatus.success ||
          loginResult.accessToken == null) {
        emit(LoginFacebookErrorState("Đăng nhập Facebook thất bại."));
        return;
      }
      final credential =
          FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);
      try {
        final userCredential = await _auth.signInWithCredential(credential);
        final idToken = await userCredential.user?.getIdToken();
        if (idToken != null) {
          await handleLoginResponseByServer(idToken, emit);
        } else {
          emit(LoginFacebookErrorState("Không thể lấy ID Token."));
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          await _handleDifferentCredentialCase(e, emit);
        } else {
          emit(LoginFacebookErrorState("Lỗi FirebaseAuth: ${e.message}"));
        }
      }
    } catch (error) {
      emit(LoginFacebookErrorState(
          "Lỗi đăng nhập Facebook: ${error.toString()}"));
    }
  }

  Future<void> _handleDifferentCredentialCase(
    FirebaseAuthException e,
    Emitter<LoginState> emit,
  ) async {
    final email = e.email ?? '';
    final credential = e.credential;
    if (email.isEmpty || credential == null) {
      emit(LoginFacebookErrorState("Không thể xử lý tài khoản khác nền tảng."));
      return;
    }

    try {
      final res = await apiService.get("users/getUserCustomToken?email=$email");
      if (res['status'] == 200 && res['token'] != null) {
        final userCredential = await _auth.signInWithCustomToken(res['token']);
        final currentUser = userCredential.user;
        if (currentUser != null) {
          await currentUser.linkWithCredential(credential);
          final idToken = await currentUser.getIdToken();
          await handleLoginResponseByServer(idToken!, emit);
        } else {
          emit(LoginFacebookErrorState("Lỗi liên kết tài khoản."));
        }
      } else {
        emit(LoginFacebookErrorState("Lỗi: API không trả về token hợp lệ."));
      }
    } catch (error) {
      emit(LoginFacebookErrorState(
          "Lỗi liên kết tài khoản: ${error.toString()}"));
    }
  }

  void _onResetState(ResetLoginStateEvent event, Emitter<LoginState> emit) {
    emit(LoginInitialState());
  }

  void printLongString(String text) {
    const chunkSize = 1000; // Chia thành các phần nhỏ 1000 ký tự
    for (int i = 0; i < text.length; i += chunkSize) {
      print(text.substring(i, i + chunkSize > text.length ? text.length : i + chunkSize));
    }
  }

  Future<void> handleLoginResponseByServer(
    String idToken,
    Emitter<LoginState> emit,
  ) async {
    if (kDebugMode) {
      print(idToken.toString());
    }
    try {
      final res = await apiService.postWithCookies(
        'users/login',
        {'idToken': idToken},
      );
      if (kDebugMode) {
        print(res);
      }
      if (res['success'] == true) {
        if (kDebugMode) {
          print('Đăng nhập thành công!');
        }
        final cookies = await apiService
            .getCookies(dotenv.env['FLUTTER_PUBLIC_API_ENDPOINT'] ?? '');
        if (kDebugMode) {
          printLongString('Cookies hiện tại: $cookies');
        }

        // Lấy user token
        final userData = await apiService.get('users/getUserCustomToken');
        if (kDebugMode) {
          print('Dữ liệu user: $userData');
        }

        final token = userData['token'] ?? '';
        final userId = extractUserIdFromToken(token);

        // Lưu token vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('userId', userId);

        if (res['isFirstTimeLogin'] == true) {
          emit(NewAccountState());
          return;
        } else {
          // Lấy thông tin user
          final userInfo = await apiService.get('users/getUserInfo');
          if (kDebugMode) {
            print('Thông tin user: $userInfo');
          }

          // Kiểm tra response hợp lệ
          if (userInfo['status'] == 200 && userInfo['user'] != null) {
            final user = userInfo['user'];
            await prefs.setString('userId', user['id'] ?? '');
            await prefs.setString('userName', user['name'] ?? '');
            await prefs.setString('userEmail', user['email'] ?? '');
            await prefs.setString(
                'userProfilePicture', user['profilePicture'] ?? '');
          }

          auth.login();
          emit(LoginCompletedState());
        }
      } else {
        emit(LoginErrorState("Lỗi: ${res['message']}"));
      }
    } catch (e) {
      final errorString = e.toString();
      if (kDebugMode) {
        print(errorString);
      }
      if (errorString.contains("message: Email not verified")) {
        emit(DoVerifiedLoginState());
        return;
      }
      final GoogleSignIn googleSignIn = GoogleSignIn();

      if (await googleSignIn.isSignedIn()) {
        // Kiểm tra nếu đã đăng nhập
        await googleSignIn.signOut();
      }

      await FirebaseAuth.instance.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      await apiService.clearCookies();
      emit(LoginErrorState("Lỗi xử lý phản hồi từ server: ${e.toString()}"));
    }
  }
}
