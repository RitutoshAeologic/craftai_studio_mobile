import 'package:get/get.dart';

class ShellController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxDouble userCredits = 120.0.obs;

  void switchTab(int index) {
    currentIndex.value = index;
  }

  void deductCredits(double amount) {
    if (userCredits.value >= amount) {
      userCredits.value -= amount;
    }
  }

  void addCredits(double amount) {
    userCredits.value += amount;
  }
}
