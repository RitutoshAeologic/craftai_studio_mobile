import "package:flutter_test/flutter_test.dart";
import "package:craftai_studio_mobile/data/models/explore_card_model.dart";
import "package:craftai_studio_mobile/data/models/job_model.dart";
import "package:craftai_studio_mobile/data/models/wallet_model.dart";

void main() {
  test("ExploreCardModel and JobModel serialization test", () {
    final card = ExploreCardModel(
      id: "card_1",
      authorName: "Studio Master",
      authorHandle: "@studiomaster",
      authorAvatar: "https://example.com/avatar.jpg",
      title: "Cyberpunk Samurai",
      previewUrl: "https://example.com/samurai.jpg",
      category: "Cinematic",
      maskedSummary: "masterpiece, 8k, neon lighting",
      remixFee: 1.0,
      creatorRoyaltyCut: 0.15,
      remixCount: 14,
      likeCount: 95,
      isLiked: false,
    );
    expect(card.id, "card_1");
    expect(card.category, "Cinematic");

    final job = JobModel(
      jobId: "job_1",
      type: "Image",
      status: "COMPLETED",
      prompt: "masterpiece, 8k",
      previewUrl: "https://example.com/job.jpg",
      creditsDeducted: 1.0,
      isDownloadUnlocked: false,
      downloadCost: 2.0,
      createdAt: DateTime.now(),
    );
    expect(job.downloadCost, 2.0);
    expect(job.isDownloadUnlocked, false);

    final unlockedJob = job.copyWith(isDownloadUnlocked: true);
    expect(unlockedJob.isDownloadUnlocked, true);

    final wallet = WalletModel(
      purchasedBalance: 100.0,
      earnedRoyaltyBalance: 50.0,
      freeDailyBalance: 10.0,
      totalGenerations: 42,
      totalRoyaltiesEarned: 15.0,
    );
    expect(wallet.totalSpendable, 160.0);
    expect(wallet.isEligibleForPayout, true);
  });
}
