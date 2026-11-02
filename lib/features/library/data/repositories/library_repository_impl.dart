import 'package:craftai_studio_mobile/core/utils/app_logger.dart';
import 'package:craftai_studio_mobile/data/models/job_model.dart';
import '../../domain/repositories/i_library_repository.dart';
import '../datasources/library_remote_datasource.dart';

/// Implementation of [ILibraryRepository] that orchestrates data access
/// through [LibraryRemoteDataSource].
class LibraryRepositoryImpl implements ILibraryRepository {
  final LibraryRemoteDataSource _remoteDataSource;

  LibraryRepositoryImpl({
    LibraryRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? LibraryRemoteDataSource();

  @override
  Future<List<JobModel>> getUserCreations({
    required int page,
    required int pageSize,
  }) async {
    try {
      return await _remoteDataSource.fetchUserCreations(
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      AppLogger.w('LibraryRepositoryImpl getUserCreations error: $e', tag: 'LIBRARY_REPO');
      rethrow;
    }
  }

  @override
  Future<void> saveCreation(JobModel job) async {
    try {
      await _remoteDataSource.saveCreation(job);
    } catch (e) {
      AppLogger.w('LibraryRepositoryImpl saveCreation error: $e', tag: 'LIBRARY_REPO');
    }
  }

  @override
  Future<bool> deleteCreation(JobModel job) async {
    try {
      return await _remoteDataSource.deleteCreation(job);
    } catch (e) {
      AppLogger.w('LibraryRepositoryImpl deleteCreation error: $e', tag: 'LIBRARY_REPO');
      return false;
    }
  }

  @override
  Future<bool> unlock4KDownload(String jobId) async {
    try {
      return await _remoteDataSource.unlock4KDownload(jobId);
    } catch (e) {
      AppLogger.w('LibraryRepositoryImpl unlock4KDownload error: $e', tag: 'LIBRARY_REPO');
      return false;
    }
  }
}

