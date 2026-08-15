import 'api_client.dart';

/// True when the user signed in with Firebase and the API receives Bearer tokens.
bool isLiveSession(ApiClient client) => client.idToken != null;
