// Mocks generated by Mockito 5.4.6 from annotations
// in chords_app/test/helpers/mock_services.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i6;

import 'package:chords_app/models/artist.dart' as _i10;
import 'package:chords_app/models/collection.dart' as _i11;
import 'package:chords_app/models/search_filters.dart' as _i16;
import 'package:chords_app/models/setlist.dart' as _i12;
import 'package:chords_app/models/song.dart' as _i4;
import 'package:chords_app/services/api_service.dart' as _i5;
import 'package:chords_app/services/audio_service.dart' as _i8;
import 'package:chords_app/services/auth_service.dart' as _i7;
import 'package:chords_app/services/cache_service.dart' as _i9;
import 'package:chords_app/services/offline_service.dart' as _i13;
import 'package:chords_app/services/song_service.dart' as _i15;
import 'package:chords_app/services/user_progress_service.dart' as _i17;
import 'package:dio/dio.dart' as _i2;
import 'package:firebase_auth/firebase_auth.dart' as _i3;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i14;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeResponse_0<T> extends _i1.SmartFake implements _i2.Response<T> {
  _FakeResponse_0(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeOptions_1 extends _i1.SmartFake implements _i2.Options {
  _FakeOptions_1(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeUserCredential_2 extends _i1.SmartFake
    implements _i3.UserCredential {
  _FakeUserCredential_2(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeSong_3 extends _i1.SmartFake implements _i4.Song {
  _FakeSong_3(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

/// A class which mocks [ApiService].
///
/// See the documentation for Mockito's code generation for more information.
class MockApiService extends _i1.Mock implements _i5.ApiService {
  MockApiService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i6.Future<_i2.Response<dynamic>> get(
    String? path, {
    Map<String, dynamic>? queryParameters,
    _i2.Options? options,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #get,
              [path],
              {#queryParameters: queryParameters, #options: options},
            ),
            returnValue: _i6.Future<_i2.Response<dynamic>>.value(
              _FakeResponse_0<dynamic>(
                this,
                Invocation.method(
                  #get,
                  [path],
                  {#queryParameters: queryParameters, #options: options},
                ),
              ),
            ),
          )
          as _i6.Future<_i2.Response<dynamic>>);

  @override
  _i6.Future<_i2.Response<dynamic>> post(
    String? path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    _i2.Options? options,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #post,
              [path],
              {
                #data: data,
                #queryParameters: queryParameters,
                #options: options,
              },
            ),
            returnValue: _i6.Future<_i2.Response<dynamic>>.value(
              _FakeResponse_0<dynamic>(
                this,
                Invocation.method(
                  #post,
                  [path],
                  {
                    #data: data,
                    #queryParameters: queryParameters,
                    #options: options,
                  },
                ),
              ),
            ),
          )
          as _i6.Future<_i2.Response<dynamic>>);

  @override
  _i6.Future<_i2.Response<dynamic>> postWithoutApiPrefix(
    String? path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    _i2.Options? options,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #postWithoutApiPrefix,
              [path],
              {
                #data: data,
                #queryParameters: queryParameters,
                #options: options,
              },
            ),
            returnValue: _i6.Future<_i2.Response<dynamic>>.value(
              _FakeResponse_0<dynamic>(
                this,
                Invocation.method(
                  #postWithoutApiPrefix,
                  [path],
                  {
                    #data: data,
                    #queryParameters: queryParameters,
                    #options: options,
                  },
                ),
              ),
            ),
          )
          as _i6.Future<_i2.Response<dynamic>>);

  @override
  _i6.Future<_i2.Response<dynamic>> put(
    String? path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    _i2.Options? options,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #put,
              [path],
              {
                #data: data,
                #queryParameters: queryParameters,
                #options: options,
              },
            ),
            returnValue: _i6.Future<_i2.Response<dynamic>>.value(
              _FakeResponse_0<dynamic>(
                this,
                Invocation.method(
                  #put,
                  [path],
                  {
                    #data: data,
                    #queryParameters: queryParameters,
                    #options: options,
                  },
                ),
              ),
            ),
          )
          as _i6.Future<_i2.Response<dynamic>>);

  @override
  _i6.Future<_i2.Response<dynamic>> delete(
    String? path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    _i2.Options? options,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #delete,
              [path],
              {
                #data: data,
                #queryParameters: queryParameters,
                #options: options,
              },
            ),
            returnValue: _i6.Future<_i2.Response<dynamic>>.value(
              _FakeResponse_0<dynamic>(
                this,
                Invocation.method(
                  #delete,
                  [path],
                  {
                    #data: data,
                    #queryParameters: queryParameters,
                    #options: options,
                  },
                ),
              ),
            ),
          )
          as _i6.Future<_i2.Response<dynamic>>);

  @override
  _i2.Options getAuthOptions(String? token) =>
      (super.noSuchMethod(
            Invocation.method(#getAuthOptions, [token]),
            returnValue: _FakeOptions_1(
              this,
              Invocation.method(#getAuthOptions, [token]),
            ),
          )
          as _i2.Options);

  @override
  _i6.Future<_i2.Response<dynamic>> patch(
    String? path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    _i2.Options? options,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #patch,
              [path],
              {
                #data: data,
                #queryParameters: queryParameters,
                #options: options,
              },
            ),
            returnValue: _i6.Future<_i2.Response<dynamic>>.value(
              _FakeResponse_0<dynamic>(
                this,
                Invocation.method(
                  #patch,
                  [path],
                  {
                    #data: data,
                    #queryParameters: queryParameters,
                    #options: options,
                  },
                ),
              ),
            ),
          )
          as _i6.Future<_i2.Response<dynamic>>);

  @override
  _i6.Future<void> clearCache() =>
      (super.noSuchMethod(
            Invocation.method(#clearCache, []),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<Map<String, dynamic>> register({
    required String? name,
    required String? email,
    required String? password,
    required bool? termsAccepted,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#register, [], {
              #name: name,
              #email: email,
              #password: password,
              #termsAccepted: termsAccepted,
            }),
            returnValue: _i6.Future<Map<String, dynamic>>.value(
              <String, dynamic>{},
            ),
          )
          as _i6.Future<Map<String, dynamic>>);

  @override
  _i6.Future<Map<String, dynamic>> loginWithEmail({
    required String? email,
    required String? password,
    required bool? rememberMe,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#loginWithEmail, [], {
              #email: email,
              #password: password,
              #rememberMe: rememberMe,
            }),
            returnValue: _i6.Future<Map<String, dynamic>>.value(
              <String, dynamic>{},
            ),
          )
          as _i6.Future<Map<String, dynamic>>);

  @override
  _i6.Future<Map<String, dynamic>> loginWithFirebase({
    required String? firebaseToken,
    required String? authProvider,
    String? name,
    required bool? rememberMe,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#loginWithFirebase, [], {
              #firebaseToken: firebaseToken,
              #authProvider: authProvider,
              #name: name,
              #rememberMe: rememberMe,
            }),
            returnValue: _i6.Future<Map<String, dynamic>>.value(
              <String, dynamic>{},
            ),
          )
          as _i6.Future<Map<String, dynamic>>);

  @override
  _i6.Future<bool> logout() =>
      (super.noSuchMethod(
            Invocation.method(#logout, []),
            returnValue: _i6.Future<bool>.value(false),
          )
          as _i6.Future<bool>);

  @override
  _i6.Future<Map<String, dynamic>> getCurrentUser() =>
      (super.noSuchMethod(
            Invocation.method(#getCurrentUser, []),
            returnValue: _i6.Future<Map<String, dynamic>>.value(
              <String, dynamic>{},
            ),
          )
          as _i6.Future<Map<String, dynamic>>);

  @override
  _i6.Future<Map<String, dynamic>> updateProfile({
    required String? name,
    String? email,
    String? phoneNumber,
    String? profilePicture,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#updateProfile, [], {
              #name: name,
              #email: email,
              #phoneNumber: phoneNumber,
              #profilePicture: profilePicture,
            }),
            returnValue: _i6.Future<Map<String, dynamic>>.value(
              <String, dynamic>{},
            ),
          )
          as _i6.Future<Map<String, dynamic>>);

  @override
  _i6.Future<Map<String, dynamic>> sendPasswordResetEmail({
    required String? email,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#sendPasswordResetEmail, [], {#email: email}),
            returnValue: _i6.Future<Map<String, dynamic>>.value(
              <String, dynamic>{},
            ),
          )
          as _i6.Future<Map<String, dynamic>>);

  @override
  _i6.Future<Map<String, dynamic>> getUserProfile() =>
      (super.noSuchMethod(
            Invocation.method(#getUserProfile, []),
            returnValue: _i6.Future<Map<String, dynamic>>.value(
              <String, dynamic>{},
            ),
          )
          as _i6.Future<Map<String, dynamic>>);
}

/// A class which mocks [AuthService].
///
/// See the documentation for Mockito's code generation for more information.
class MockAuthService extends _i1.Mock implements _i7.AuthService {
  MockAuthService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i6.Future<void> initializeFirebase() =>
      (super.noSuchMethod(
            Invocation.method(#initializeFirebase, []),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<Map<String, dynamic>> registerWithEmail({
    required String? name,
    required String? email,
    required String? password,
    required bool? termsAccepted,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#registerWithEmail, [], {
              #name: name,
              #email: email,
              #password: password,
              #termsAccepted: termsAccepted,
            }),
            returnValue: _i6.Future<Map<String, dynamic>>.value(
              <String, dynamic>{},
            ),
          )
          as _i6.Future<Map<String, dynamic>>);

  @override
  _i6.Future<Map<String, dynamic>> loginWithEmail({
    required String? email,
    required String? password,
    required bool? rememberMe,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#loginWithEmail, [], {
              #email: email,
              #password: password,
              #rememberMe: rememberMe,
            }),
            returnValue: _i6.Future<Map<String, dynamic>>.value(
              <String, dynamic>{},
            ),
          )
          as _i6.Future<Map<String, dynamic>>);

  @override
  _i6.Future<_i3.UserCredential> signInWithGoogle() =>
      (super.noSuchMethod(
            Invocation.method(#signInWithGoogle, []),
            returnValue: _i6.Future<_i3.UserCredential>.value(
              _FakeUserCredential_2(
                this,
                Invocation.method(#signInWithGoogle, []),
              ),
            ),
          )
          as _i6.Future<_i3.UserCredential>);

  @override
  _i6.Future<bool> isLoggedIn() =>
      (super.noSuchMethod(
            Invocation.method(#isLoggedIn, []),
            returnValue: _i6.Future<bool>.value(false),
          )
          as _i6.Future<bool>);

  @override
  _i6.Future<String?> getToken() =>
      (super.noSuchMethod(
            Invocation.method(#getToken, []),
            returnValue: _i6.Future<String?>.value(),
          )
          as _i6.Future<String?>);

  @override
  _i6.Future<String?> refreshToken() =>
      (super.noSuchMethod(
            Invocation.method(#refreshToken, []),
            returnValue: _i6.Future<String?>.value(),
          )
          as _i6.Future<String?>);

  @override
  _i6.Future<Map<String, dynamic>> loginWithGoogle({
    required bool? rememberMe,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#loginWithGoogle, [], {#rememberMe: rememberMe}),
            returnValue: _i6.Future<Map<String, dynamic>>.value(
              <String, dynamic>{},
            ),
          )
          as _i6.Future<Map<String, dynamic>>);

  @override
  _i6.Future<Map<String, dynamic>> loginWithFacebook({
    required bool? rememberMe,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#loginWithFacebook, [], {
              #rememberMe: rememberMe,
            }),
            returnValue: _i6.Future<Map<String, dynamic>>.value(
              <String, dynamic>{},
            ),
          )
          as _i6.Future<Map<String, dynamic>>);

  @override
  _i6.Future<Map<String, dynamic>> loginWithApple({
    required bool? rememberMe,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#loginWithApple, [], {#rememberMe: rememberMe}),
            returnValue: _i6.Future<Map<String, dynamic>>.value(
              <String, dynamic>{},
            ),
          )
          as _i6.Future<Map<String, dynamic>>);

  @override
  _i6.Future<void> signOut() =>
      (super.noSuchMethod(
            Invocation.method(#signOut, []),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<Map<String, dynamic>> logout() =>
      (super.noSuchMethod(
            Invocation.method(#logout, []),
            returnValue: _i6.Future<Map<String, dynamic>>.value(
              <String, dynamic>{},
            ),
          )
          as _i6.Future<Map<String, dynamic>>);

  @override
  _i6.Future<Map<String, dynamic>> sendPasswordResetEmail({
    required String? email,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#sendPasswordResetEmail, [], {#email: email}),
            returnValue: _i6.Future<Map<String, dynamic>>.value(
              <String, dynamic>{},
            ),
          )
          as _i6.Future<Map<String, dynamic>>);
}

/// A class which mocks [AudioService].
///
/// See the documentation for Mockito's code generation for more information.
class MockAudioService extends _i1.Mock implements _i8.AudioService {
  MockAudioService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  Map<String, double> get standardTuning =>
      (super.noSuchMethod(
            Invocation.getter(#standardTuning),
            returnValue: <String, double>{},
          )
          as Map<String, double>);

  @override
  _i6.Stream<_i8.TuningResult> get tuningResultStream =>
      (super.noSuchMethod(
            Invocation.getter(#tuningResultStream),
            returnValue: _i6.Stream<_i8.TuningResult>.empty(),
          )
          as _i6.Stream<_i8.TuningResult>);

  @override
  void dispose() => super.noSuchMethod(
    Invocation.method(#dispose, []),
    returnValueForMissingStub: null,
  );
}

/// A class which mocks [CacheService].
///
/// See the documentation for Mockito's code generation for more information.
class MockCacheService extends _i1.Mock implements _i9.CacheService {
  MockCacheService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i6.Future<void> initialize() =>
      (super.noSuchMethod(
            Invocation.method(#initialize, []),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  bool shouldUseCacheForSession() =>
      (super.noSuchMethod(
            Invocation.method(#shouldUseCacheForSession, []),
            returnValue: false,
          )
          as bool);

  @override
  _i6.Future<void> clearAllCache() =>
      (super.noSuchMethod(
            Invocation.method(#clearAllCache, []),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<void> cacheSongs(List<_i4.Song>? songs) =>
      (super.noSuchMethod(
            Invocation.method(#cacheSongs, [songs]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<List<_i4.Song>?> getCachedSongs() =>
      (super.noSuchMethod(
            Invocation.method(#getCachedSongs, []),
            returnValue: _i6.Future<List<_i4.Song>?>.value(),
          )
          as _i6.Future<List<_i4.Song>?>);

  @override
  _i6.Future<void> cacheArtists(List<_i10.Artist>? artists) =>
      (super.noSuchMethod(
            Invocation.method(#cacheArtists, [artists]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<List<_i10.Artist>?> getCachedArtists() =>
      (super.noSuchMethod(
            Invocation.method(#getCachedArtists, []),
            returnValue: _i6.Future<List<_i10.Artist>?>.value(),
          )
          as _i6.Future<List<_i10.Artist>?>);

  @override
  _i6.Future<void> cacheSeasonalCollections(
    List<_i11.Collection>? collections,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#cacheSeasonalCollections, [collections]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<List<_i11.Collection>?> getCachedSeasonalCollections() =>
      (super.noSuchMethod(
            Invocation.method(#getCachedSeasonalCollections, []),
            returnValue: _i6.Future<List<_i11.Collection>?>.value(),
          )
          as _i6.Future<List<_i11.Collection>?>);

  @override
  _i6.Future<void> cacheBeginnerCollections(
    List<_i11.Collection>? collections,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#cacheBeginnerCollections, [collections]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<List<_i11.Collection>?> getCachedBeginnerCollections() =>
      (super.noSuchMethod(
            Invocation.method(#getCachedBeginnerCollections, []),
            returnValue: _i6.Future<List<_i11.Collection>?>.value(),
          )
          as _i6.Future<List<_i11.Collection>?>);

  @override
  _i6.Future<void> cacheTrendingSongs(List<_i4.Song>? songs) =>
      (super.noSuchMethod(
            Invocation.method(#cacheTrendingSongs, [songs]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<List<_i4.Song>?> getCachedTrendingSongs() =>
      (super.noSuchMethod(
            Invocation.method(#getCachedTrendingSongs, []),
            returnValue: _i6.Future<List<_i4.Song>?>.value(),
          )
          as _i6.Future<List<_i4.Song>?>);

  @override
  _i6.Future<void> cacheTopArtists(List<_i10.Artist>? artists) =>
      (super.noSuchMethod(
            Invocation.method(#cacheTopArtists, [artists]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<List<_i10.Artist>?> getCachedTopArtists() =>
      (super.noSuchMethod(
            Invocation.method(#getCachedTopArtists, []),
            returnValue: _i6.Future<List<_i10.Artist>?>.value(),
          )
          as _i6.Future<List<_i10.Artist>?>);

  @override
  _i6.Future<void> cacheNewSongs(List<_i4.Song>? songs) =>
      (super.noSuchMethod(
            Invocation.method(#cacheNewSongs, [songs]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<List<_i4.Song>?> getCachedNewSongs() =>
      (super.noSuchMethod(
            Invocation.method(#getCachedNewSongs, []),
            returnValue: _i6.Future<List<_i4.Song>?>.value(),
          )
          as _i6.Future<List<_i4.Song>?>);

  @override
  _i6.Future<void> cacheHomeSections(List<dynamic>? sections) =>
      (super.noSuchMethod(
            Invocation.method(#cacheHomeSections, [sections]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<List<dynamic>?> getCachedHomeSections() =>
      (super.noSuchMethod(
            Invocation.method(#getCachedHomeSections, []),
            returnValue: _i6.Future<List<dynamic>?>.value(),
          )
          as _i6.Future<List<dynamic>?>);

  @override
  _i6.Future<bool> isCacheStale(String? cacheKey, int? maxAgeMinutes) =>
      (super.noSuchMethod(
            Invocation.method(#isCacheStale, [cacheKey, maxAgeMinutes]),
            returnValue: _i6.Future<bool>.value(false),
          )
          as _i6.Future<bool>);

  @override
  _i6.Future<void> cacheBannerImages(List<String>? imageUrls) =>
      (super.noSuchMethod(
            Invocation.method(#cacheBannerImages, [imageUrls]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<List<String>?> getCachedBannerImages() =>
      (super.noSuchMethod(
            Invocation.method(#getCachedBannerImages, []),
            returnValue: _i6.Future<List<String>?>.value(),
          )
          as _i6.Future<List<String>?>);

  @override
  _i6.Future<bool> haveBannerImagesChanged(List<String>? newImageUrls) =>
      (super.noSuchMethod(
            Invocation.method(#haveBannerImagesChanged, [newImageUrls]),
            returnValue: _i6.Future<bool>.value(false),
          )
          as _i6.Future<bool>);

  @override
  _i6.Future<void> set(String? key, String? data) =>
      (super.noSuchMethod(
            Invocation.method(#set, [key, data]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<String?> get(String? key, {int? expirationMinutes = 30}) =>
      (super.noSuchMethod(
            Invocation.method(
              #get,
              [key],
              {#expirationMinutes: expirationMinutes},
            ),
            returnValue: _i6.Future<String?>.value(),
          )
          as _i6.Future<String?>);

  @override
  _i6.Future<void> remove(String? key) =>
      (super.noSuchMethod(
            Invocation.method(#remove, [key]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<void> cacheSetlists(List<_i12.Setlist>? setlists) =>
      (super.noSuchMethod(
            Invocation.method(#cacheSetlists, [setlists]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<List<_i12.Setlist>?> getCachedSetlists() =>
      (super.noSuchMethod(
            Invocation.method(#getCachedSetlists, []),
            returnValue: _i6.Future<List<_i12.Setlist>?>.value(),
          )
          as _i6.Future<List<_i12.Setlist>?>);

  @override
  _i6.Future<void> cacheLikedSongs(List<_i4.Song>? likedSongs) =>
      (super.noSuchMethod(
            Invocation.method(#cacheLikedSongs, [likedSongs]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<List<_i4.Song>?> getCachedLikedSongs() =>
      (super.noSuchMethod(
            Invocation.method(#getCachedLikedSongs, []),
            returnValue: _i6.Future<List<_i4.Song>?>.value(),
          )
          as _i6.Future<List<_i4.Song>?>);

  @override
  _i6.Future<void> clearSetlistCache() =>
      (super.noSuchMethod(
            Invocation.method(#clearSetlistCache, []),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);
}

/// A class which mocks [OfflineService].
///
/// See the documentation for Mockito's code generation for more information.
class MockOfflineService extends _i1.Mock implements _i13.OfflineService {
  MockOfflineService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  bool get isOnline =>
      (super.noSuchMethod(Invocation.getter(#isOnline), returnValue: false)
          as bool);

  @override
  bool get isOffline =>
      (super.noSuchMethod(Invocation.getter(#isOffline), returnValue: false)
          as bool);

  @override
  bool get offlineModeEnabled =>
      (super.noSuchMethod(
            Invocation.getter(#offlineModeEnabled),
            returnValue: false,
          )
          as bool);

  @override
  _i6.Future<void> initialize() =>
      (super.noSuchMethod(
            Invocation.method(#initialize, []),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<void> setOfflineModeEnabled(bool? enabled) =>
      (super.noSuchMethod(
            Invocation.method(#setOfflineModeEnabled, [enabled]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<void> cacheSongsForOffline(List<_i4.Song>? songs) =>
      (super.noSuchMethod(
            Invocation.method(#cacheSongsForOffline, [songs]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<List<_i4.Song>?> getCachedSongs() =>
      (super.noSuchMethod(
            Invocation.method(#getCachedSongs, []),
            returnValue: _i6.Future<List<_i4.Song>?>.value(),
          )
          as _i6.Future<List<_i4.Song>?>);

  @override
  _i6.Future<void> cacheArtistsForOffline(List<_i10.Artist>? artists) =>
      (super.noSuchMethod(
            Invocation.method(#cacheArtistsForOffline, [artists]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<List<_i10.Artist>?> getCachedArtists() =>
      (super.noSuchMethod(
            Invocation.method(#getCachedArtists, []),
            returnValue: _i6.Future<List<_i10.Artist>?>.value(),
          )
          as _i6.Future<List<_i10.Artist>?>);

  @override
  _i6.Future<void> cacheCollectionsForOffline(
    List<_i11.Collection>? collections,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#cacheCollectionsForOffline, [collections]),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  _i6.Future<List<_i11.Collection>?> getCachedCollections() =>
      (super.noSuchMethod(
            Invocation.method(#getCachedCollections, []),
            returnValue: _i6.Future<List<_i11.Collection>?>.value(),
          )
          as _i6.Future<List<_i11.Collection>?>);

  @override
  _i6.Future<bool> hasOfflineData() =>
      (super.noSuchMethod(
            Invocation.method(#hasOfflineData, []),
            returnValue: _i6.Future<bool>.value(false),
          )
          as _i6.Future<bool>);

  @override
  _i6.Future<DateTime?> getLastSyncTime() =>
      (super.noSuchMethod(
            Invocation.method(#getLastSyncTime, []),
            returnValue: _i6.Future<DateTime?>.value(),
          )
          as _i6.Future<DateTime?>);

  @override
  _i6.Future<void> clearOfflineData() =>
      (super.noSuchMethod(
            Invocation.method(#clearOfflineData, []),
            returnValue: _i6.Future<void>.value(),
            returnValueForMissingStub: _i6.Future<void>.value(),
          )
          as _i6.Future<void>);

  @override
  bool shouldUseOfflineData() =>
      (super.noSuchMethod(
            Invocation.method(#shouldUseOfflineData, []),
            returnValue: false,
          )
          as bool);

  @override
  String getOfflineStatusMessage() =>
      (super.noSuchMethod(
            Invocation.method(#getOfflineStatusMessage, []),
            returnValue: _i14.dummyValue<String>(
              this,
              Invocation.method(#getOfflineStatusMessage, []),
            ),
          )
          as String);

  @override
  void dispose() => super.noSuchMethod(
    Invocation.method(#dispose, []),
    returnValueForMissingStub: null,
  );
}

/// A class which mocks [SongService].
///
/// See the documentation for Mockito's code generation for more information.
class MockSongService extends _i1.Mock implements _i15.SongService {
  MockSongService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i6.Future<Map<String, dynamic>> getPaginatedSongs({
    int? page = 1,
    int? limit = 20,
    String? search,
    String? artistId,
    String? tags,
    String? sortBy,
    String? sortOrder,
    bool? forceRefresh = false,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#getPaginatedSongs, [], {
              #page: page,
              #limit: limit,
              #search: search,
              #artistId: artistId,
              #tags: tags,
              #sortBy: sortBy,
              #sortOrder: sortOrder,
              #forceRefresh: forceRefresh,
            }),
            returnValue: _i6.Future<Map<String, dynamic>>.value(
              <String, dynamic>{},
            ),
          )
          as _i6.Future<Map<String, dynamic>>);

  @override
  _i6.Future<List<_i4.Song>> getAllSongs({bool? forceRefresh = false}) =>
      (super.noSuchMethod(
            Invocation.method(#getAllSongs, [], {#forceRefresh: forceRefresh}),
            returnValue: _i6.Future<List<_i4.Song>>.value(<_i4.Song>[]),
          )
          as _i6.Future<List<_i4.Song>>);

  @override
  _i6.Future<List<_i4.Song>> searchSongs(
    String? query, {
    _i16.SongSearchFilters? filters,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#searchSongs, [query], {#filters: filters}),
            returnValue: _i6.Future<List<_i4.Song>>.value(<_i4.Song>[]),
          )
          as _i6.Future<List<_i4.Song>>);

  @override
  _i6.Future<List<_i4.Song>> getSongsByArtist(String? artistId) =>
      (super.noSuchMethod(
            Invocation.method(#getSongsByArtist, [artistId]),
            returnValue: _i6.Future<List<_i4.Song>>.value(<_i4.Song>[]),
          )
          as _i6.Future<List<_i4.Song>>);

  @override
  _i6.Future<_i4.Song> getSongById(String? id) =>
      (super.noSuchMethod(
            Invocation.method(#getSongById, [id]),
            returnValue: _i6.Future<_i4.Song>.value(
              _FakeSong_3(this, Invocation.method(#getSongById, [id])),
            ),
          )
          as _i6.Future<_i4.Song>);

  @override
  _i6.Future<bool> toggleLikeSong(String? songId, bool? isLiked) =>
      (super.noSuchMethod(
            Invocation.method(#toggleLikeSong, [songId, isLiked]),
            returnValue: _i6.Future<bool>.value(false),
          )
          as _i6.Future<bool>);

  @override
  _i6.Future<List<_i4.Song>> getSongsByArtistName(String? artistName) =>
      (super.noSuchMethod(
            Invocation.method(#getSongsByArtistName, [artistName]),
            returnValue: _i6.Future<List<_i4.Song>>.value(<_i4.Song>[]),
          )
          as _i6.Future<List<_i4.Song>>);

  @override
  _i6.Future<Map<String, int>> countSongsByArtist() =>
      (super.noSuchMethod(
            Invocation.method(#countSongsByArtist, []),
            returnValue: _i6.Future<Map<String, int>>.value(<String, int>{}),
          )
          as _i6.Future<Map<String, int>>);
}

/// A class which mocks [UserProgressService].
///
/// See the documentation for Mockito's code generation for more information.
class MockUserProgressService extends _i1.Mock
    implements _i17.UserProgressService {
  MockUserProgressService() {
    _i1.throwOnMissingStub(this);
  }
}
