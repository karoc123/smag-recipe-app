import 'package:flutter_test/flutter_test.dart';
import 'package:smag/domain/cookbook_path_policy.dart';

void main() {
  group('CookbookPathPolicy', () {
    test(
      'normalizes folder paths with leading slash and no trailing slash',
      () {
        expect(CookbookPathPolicy.normalizeFolderPath('Rezepte/'), '/Rezepte');
        expect(
          CookbookPathPolicy.normalizeFolderPath('/Rezepte//Test/'),
          '/Rezepte/Test',
        );
      },
    );

    test('detects paths inside cookbook folder', () {
      expect(
        CookbookPathPolicy.isPathInsideFolder(
          path: '/Rezepte/test/full.jpg',
          folderPath: '/Rezepte',
        ),
        isTrue,
      );
      expect(
        CookbookPathPolicy.isPathInsideFolder(
          path: '/Andere/test/full.jpg',
          folderPath: '/Rezepte',
        ),
        isFalse,
      );
    });

    test('throws for access outside cookbook folder', () {
      expect(
        () => CookbookPathPolicy.assertPathInsideFolder(
          path: '/outside.jpg',
          folderPath: '/Rezepte',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
