import 'package:get/get.dart';
import '../../domain/repositories/i_studio_repository.dart';
import '../../data/datasources/studio_remote_datasource.dart';
import '../../data/repositories/studio_repository_impl.dart';
import '../controllers/studio_controller.dart';
import '../controllers/prompt_chat_copilot_controller.dart';

class StudioBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudioRemoteDataSource>(() => StudioRemoteDataSource());
    Get.lazyPut<IStudioRepository>(() => StudioRepositoryImpl(
          remoteDataSource: Get.find<StudioRemoteDataSource>(),
        ));
    Get.lazyPut<StudioController>(() => StudioController(
          repository: Get.find<IStudioRepository>(),
        ));
    Get.lazyPut<PromptChatCopilotController>(() => PromptChatCopilotController(
          repository: Get.find<IStudioRepository>(),
        ));
  }
}
