import 'package:equatable/equatable.dart';

abstract class LibraryEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class ToggleViewEvent extends LibraryEvent {}
