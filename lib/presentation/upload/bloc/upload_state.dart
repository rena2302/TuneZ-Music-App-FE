abstract class UploadState {}

class UploadInitial extends UploadState {}

class UploadLoading extends UploadState {}

class UploadSuccess extends UploadState {}

class UploadError extends UploadState {
  final String message;
  UploadError(this.message);
} 