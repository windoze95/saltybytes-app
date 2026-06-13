import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper_platform_interface/image_cropper_platform_interface.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/features/import/import_photo_screen.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_helpers.dart';

/// 1x1 transparent PNG so Image.file can decode without errors.
final _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
  'AAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

class _FakeImagePickerPlatform extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  _FakeImagePickerPlatform(this.path);

  final String path;
  int pickCalls = 0;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    pickCalls++;
    return XFile(path);
  }
}

class _FakeImageCropperPlatform extends ImageCropperPlatform
    with MockPlatformInterfaceMixin {
  _FakeImageCropperPlatform(this.path);

  final String path;

  @override
  Future<CroppedFile?> cropImage({
    required String sourcePath,
    int? maxWidth,
    int? maxHeight,
    CropAspectRatio? aspectRatio,
    ImageCompressFormat compressFormat = ImageCompressFormat.jpg,
    int compressQuality = 90,
    List<PlatformUiSettings>? uiSettings,
  }) async {
    return CroppedFile(path);
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late Directory tempDir;
  late String imagePath;
  late MockApiClient apiClient;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('import_photo_test');
    imagePath = '${tempDir.path}/recipe.png';
    File(imagePath).writeAsBytesSync(_onePixelPng);

    ImagePickerPlatform.instance = _FakeImagePickerPlatform(imagePath);
    ImageCropperPlatform.instance = _FakeImageCropperPlatform(imagePath);

    apiClient = MockApiClient();
    container = ProviderContainer(overrides: [
      apiClientProvider.overrideWithValue(apiClient),
      authStateProvider.overrideWith(FakeAuthNotifier.new),
    ]);

    when(() => apiClient.post(
          ApiEndpoints.importFromPhoto,
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => fakeResponse<dynamic>(
        {'recipe': testRecipeJson(id: 'r-photo-1', title: 'Scanned Brownies')}));

    router = GoRouter(
      initialLocation: '/import/photo',
      routes: [
        GoRoute(
          path: '/import/photo',
          builder: (_, __) => const ImportPhotoScreen(),
        ),
        GoRoute(
          path: '/recipe/:id',
          builder: (_, state) => Scaffold(
            body: Text('detail-${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    tempDir.deleteSync(recursive: true);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pickFromGallery(WidgetTester tester) async {
    await tester.tap(find.text('Gallery'));
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Taps Extract Recipe and lets the real file IO behind
  /// MultipartFile.fromFile complete (requires runAsync).
  Future<void> extract(WidgetTester tester) async {
    await tester.tap(find.text('Extract Recipe'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ImportPhotoScreen', () {
    testWidgets('shows picker buttons and no extract button before a photo',
        (tester) async {
      await pumpScreen(tester);

      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Extract Recipe'), findsNothing);
    });

    testWidgets('picking a photo reveals the extract button', (tester) async {
      await pumpScreen(tester);
      await pickFromGallery(tester);

      expect(find.text('Extract Recipe'), findsOneWidget);
      expect(find.text('Retake'), findsOneWidget);
      expect(find.text('Choose Another'), findsOneWidget);
    });

    testWidgets(
        'successful extraction posts multipart image and parses envelope',
        (tester) async {
      await pumpScreen(tester);
      await pickFromGallery(tester);
      await extract(tester);

      // Envelope {"recipe": {...}} is unwrapped and rendered.
      expect(find.text('Scanned Brownies'), findsOneWidget);
      expect(find.text('View Recipe'), findsOneWidget);

      // Single-shot: button is now a disabled 'Imported'.
      final imported = find.widgetWithText(ElevatedButton, 'Imported');
      expect(imported, findsOneWidget);
      expect(tester.widget<ElevatedButton>(imported).onPressed, isNull);

      final captured = verify(() => apiClient.post(
            ApiEndpoints.importFromPhoto,
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single as FormData;
      expect(captured.files, hasLength(1));
      expect(captured.files.single.key, 'image');
      expect(captured.files.single.value.filename, 'recipe_image.jpg');
    });

    testWidgets('View Recipe navigates to the imported recipe',
        (tester) async {
      await pumpScreen(tester);
      await pickFromGallery(tester);
      await extract(tester);

      await tester.tap(find.text('View Recipe'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('detail-r-photo-1'), findsOneWidget);
    });

    testWidgets('failure shows the error state without retrying silently',
        (tester) async {
      when(() => apiClient.post(
            ApiEndpoints.importFromPhoto,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => throw DioException(
            requestOptions: RequestOptions(path: ApiEndpoints.importFromPhoto),
          ));

      await pumpScreen(tester);
      await pickFromGallery(tester);
      await extract(tester);

      expect(
        find.text(
            'Could not extract recipe from this image. Try a clearer photo.'),
        findsOneWidget,
      );
      expect(find.text('View Recipe'), findsNothing);

      // Button returns to an enabled manual-retry state and exactly one
      // request was made (no automatic retry loop).
      final extractButton =
          find.widgetWithText(ElevatedButton, 'Extract Recipe');
      expect(tester.widget<ElevatedButton>(extractButton).onPressed, isNotNull);
      await tester.pump(const Duration(seconds: 2));
      verify(() => apiClient.post(
            ApiEndpoints.importFromPhoto,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).called(1);
    });
  });
}
