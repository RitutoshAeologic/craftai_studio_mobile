import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UI/UX Integrity & Visual Guard Contract Tests', () {
    final libDir = Directory('lib');

    List<File> getDartFiles(Directory dir) {
      final files = <File>[];
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          files.add(entity);
        }
      }
      return files;
    }

    test('No button widget mixes an Icon parameter with an emoji in its label', () {
      final dartFiles = getDartFiles(libDir);
      final emojiPattern = RegExp(r'[⚡✨🖐️]');
      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          if ((line.contains('ElevatedButton.icon') ||
                  line.contains('AppButton') ||
                  line.contains('ModernAiButton') ||
                  line.contains('TextButton.icon')) &&
              !line.contains('//')) {
            final start = i;
            final end = (i + 15).clamp(0, lines.length);
            final snippet = lines.sublist(start, end).join('\n');

            final hasIconParam = snippet.contains('icon:') &&
                !snippet.contains('icon: null');

            final textMatch = RegExp(r'label:\s*(?:const\s+)?Text\s*\(\s*["\x27]([^"\x27]+)["\x27]').firstMatch(snippet) ??
                RegExp(r'label:\s*["\x27]([^"\x27]+)["\x27]').firstMatch(snippet);

            if (hasIconParam && textMatch != null) {
              final labelText = textMatch.group(1)!;
              if (emojiPattern.hasMatch(labelText)) {
                violations.add(
                    '${file.path}:${i + 1} has duplicate icon+emoji: "$labelText"');
              }
            }
          }
        }
      }

      expect(violations, isEmpty,
          reason: 'Buttons must not mix Icon() with emojis in label text: \n${violations.join('\n')}');
    });

    test('Remix CTA in Explore details routes directly to RemixChatView', () {
      final exploreDetailFile = File('lib/features/explore/views/explore_image_detail_view.dart');
      expect(exploreDetailFile.existsSync(), isTrue);

      final content = exploreDetailFile.readAsStringSync();
      // Remix button must navigate to RemixChatView
      expect(content.contains('Remix in Lab'), isTrue);
      expect(content.contains('RemixChatView'), isTrue);
    });

    test('No empty/dummy button callbacks exist in production UI code', () {
      final dartFiles = getDartFiles(libDir);
      final emptyCallbackPattern = RegExp(r'onPressed:\s*\(\)\s*\{\s*\}');
      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (emptyCallbackPattern.hasMatch(line) && !line.startsWith('//')) {
            violations.add('${file.path}:${i + 1} -> $line');
          }
        }
      }

      expect(violations, isEmpty,
          reason: 'Production UI code must not contain empty onPressed callbacks: \n${violations.join('\n')}');
    });
  });
}
