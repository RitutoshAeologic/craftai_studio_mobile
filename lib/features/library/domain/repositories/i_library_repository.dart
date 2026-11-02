import 'package:craftai_studio_mobile/data/models/job_model.dart';

/// Abstract domain repository contract for the Cloud Library.
///
/// Follows Clean Architecture: Presentation layer interacts only with this
/// interface, decoupling UI controllers from Supabase and REST API details.
abstract class ILibraryRepository {
  /// Fetches a paginated slice of the authenticated user's generation jobs.
  Future<List<JobModel>> getUserCreations({
    required int page,
    required int pageSize,
  });

  /// Persists a new creation job to cloud database and storage.
  Future<void> saveCreation(JobModel job);

  /// Permanently removes a creation from backend, Supabase database, and storage bucket.
  Future<bool> deleteCreation(JobModel job);

  /// Unlocks 4K master download status in cloud database.
  Future<bool> unlock4KDownload(String jobId);
}

