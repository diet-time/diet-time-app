import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/personalization/data/profile_link_repository.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileLinkState {
  const ProfileLinkState({
    this.isLinking = false,
    this.isLinked = false,
    this.errorMessage,
  });

  final bool isLinking;
  final bool isLinked;
  final String? errorMessage;
}

final profileLinkControllerProvider =
    NotifierProvider<ProfileLinkController, ProfileLinkState>(
      ProfileLinkController.new,
    );

class ProfileLinkController extends Notifier<ProfileLinkState> {
  @override
  ProfileLinkState build() => const ProfileLinkState();

  Future<bool> link() async {
    if (state.isLinking) return false;
    state = const ProfileLinkState(isLinking: true);
    try {
      final profile = await ref
          .read(profileLinkRepositoryProvider)
          .linkGuestProfile();
      if (profile != null) {
        ref.read(personalizationControllerProvider.notifier).replace(profile);
        final storage = ref.read(secureStorageServiceProvider);
        await storage.delete(SecureStorageService.guestTokenKey);
        await storage.delete(SecureStorageService.guestTokenExpiryKey);
      }
      state = const ProfileLinkState(isLinked: true);
      return true;
    } on Object {
      state = const ProfileLinkState(
        errorMessage: 'Your profile could not be linked. Please retry.',
      );
      return false;
    }
  }
}
