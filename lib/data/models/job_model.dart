class JobModel {
  final String jobId;
  final String type;
  final String status;
  final String prompt;
  final String previewUrl;
  final String? masterUrl;
  final double creditsDeducted;
  final bool isDownloadUnlocked;
  final double downloadCost;
  final DateTime createdAt;

  JobModel({
    required this.jobId,
    required this.type,
    required this.status,
    required this.prompt,
    required this.previewUrl,
    this.masterUrl,
    required this.creditsDeducted,
    this.isDownloadUnlocked = false,
    this.downloadCost = 2.0,
    required this.createdAt,
  });

  JobModel copyWith({bool? isDownloadUnlocked}) {
    return JobModel(
      jobId: jobId,
      type: type,
      status: status,
      prompt: prompt,
      previewUrl: previewUrl,
      masterUrl: masterUrl,
      creditsDeducted: creditsDeducted,
      isDownloadUnlocked: isDownloadUnlocked ?? this.isDownloadUnlocked,
      downloadCost: downloadCost,
      createdAt: createdAt,
    );
  }
}
