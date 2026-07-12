import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/core/settings/app_settings_store.dart';
import 'package:eduself_study_app/features/auth/domain/entities/user.dart';
import 'package:eduself_study_app/features/auth/infrastructure/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthRepositoryImpl repo;
  late AppSettingsStore settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = AppSettingsStore(
      prefs: await SharedPreferences.getInstance(),
      memorySecure: <String, String>{},
    );
  });

  AuthRepositoryImpl buildRepo(MockClient client) {
    final api = ApiClient(
      resolveBaseUrl: () => 'http://localhost:8787',
      readAccessToken: settings.readApiAccessToken,
      readRefreshToken: settings.readApiRefreshToken,
      persistTokens: (tokens) async {
        await settings.writeApiAccessToken(tokens.accessToken);
        await settings.writeApiRefreshToken(tokens.refreshToken);
      },
      clearTokens: settings.clearApiTokens,
      httpClient: client,
    );
    return AuthRepositoryImpl(api: api, settings: settings);
  }

  test('register persists tokens and returns user', () async {
    repo = buildRepo(
      MockClient((request) async {
        expect(request.url.path, '/auth/register');
        return http.Response(
          '''
{
  "data": {
    "user": {
      "id": 1,
      "email": "a@b.com",
      "role": "student",
      "createdAtUtc": "2026-01-01T00:00:00.000Z"
    },
    "tokens": {
      "accessToken": "access-1",
      "refreshToken": "refresh-1",
      "tokenType": "Bearer",
      "expiresIn": 900
    }
  }
}
''',
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await repo.register(
      email: 'a@b.com',
      password: 'password1',
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.email, 'a@b.com');
    expect(result.valueOrNull?.role, UserRole.student);
    expect(await settings.readApiAccessToken(), 'access-1');
    expect(await settings.readApiRefreshToken(), 'refresh-1');
  });

  test('login maps invalid credentials', () async {
    repo = buildRepo(
      MockClient((request) async {
        return http.Response(
          '{"error":{"code":"INVALID_CREDENTIALS","message":"bad","details":[]}}',
          401,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await repo.login(email: 'a@b.com', password: 'wrongpass');
    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<InvalidCredentialsFailure>());
  });
}
