import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppState {
  final bool isLoading;
  final String? error;
  final dynamic data;

  AppState({
    this.isLoading = false,
    this.error,
    this.data,
  });

  AppState copyWith({
    bool? isLoading,
    String? error,
    dynamic data,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      data: data ?? this.data,
    );
  }
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState());

  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
  void setError(String? error) => state = state.copyWith(error: error);
  void setData(dynamic data) => state = state.copyWith(data: data);
}
