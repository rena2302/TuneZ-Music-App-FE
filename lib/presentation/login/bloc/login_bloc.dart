import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tunezmusic/core/lib/decode_token.dart';
import 'package:tunezmusic/data/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunezmusic/presentation/login/bloc/login_event.dart';
import 'package:tunezmusic/presentation/login/bloc/login_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final ApiService apiService;
  LoginBloc(this.apiService) : super(LoginInitialState()) {
    on<LoginEmailEvent>(_onLoginByEmail);
  }

  // Xử lý sự kiện đăng nhập email
  Future<void> _onLoginByEmail(
      LoginEmailEvent event, Emitter<LoginState> emit) async {
    emit(LoginLoadingState());
    try {
      // Đăng nhập Firebase
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      if (userCredential.user == null) {
        emit(LoginErrorState(
            "Đăng nhập không thành công, tài khoản không tồn tại."));
        return;
      }

      // Lấy Firebase ID Token
      String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        emit(LoginErrorState("Không thể lấy ID Token từ Firebase."));
        return;
      }
      // Gửi ID Token lên server
      final res = await apiService.post(
        'users/login/google',
        {'idToken': idToken},
      );
      if (kDebugMode) {
         print("API Response: ${jsonEncode(res)}");
      }
      if (res['success'] == true) {
        String firebaseToken = res['firebaseToken'] ?? '';

        // Giải mã JWT để lấy userId
        String userId = extractUserIdFromToken(firebaseToken);

        // Lưu vào SharedPreferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', firebaseToken);
        await prefs.setString('userId', userId);

        emit(LoginEmailState());
      } else {
        emit(LoginErrorState("Lỗi: ${res['message']}"));
      }
    } catch (e) {
      emit(LoginErrorState("Lỗi khi đăng nhập: ${e.toString()}"));
    }
  }
}
