import 'dart:convert';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/personalization/data/customer_profile_service.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A navigation choice for this journey, separate from questionnaire completion.
final questionnaireDeferralProvider =
    NotifierProvider<QuestionnaireDeferralController, bool>(
      QuestionnaireDeferralController.new,
    );

class QuestionnaireDeferralController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> defer() async {
    final profile = ref.read(personalizationControllerProvider);
    final storage = ref.read(secureStorageServiceProvider);
    final token = await storage.read(SecureStorageService.accessTokenKey);
    final user = await storage.read(
      SecureStorageService.authenticatedUserIdKey,
    );
    final key = token?.isNotEmpty == true && user?.isNotEmpty == true
        ? 'questionnaire.user.$user'
        : CustomerProfileService.guestDraftKey;
    await storage.write(
      key,
      jsonEncode({
        ...profile.toJson(),
        'preferredLanguage': profile.preferredLanguage,
        'profileId': profile.profileId,
        'preferences': profile.preferences.toList(),
        'allergens': profile.allergens.toList(),
      }),
    );
    state = true;
  }
}
