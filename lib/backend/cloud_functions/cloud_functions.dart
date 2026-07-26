import 'package:cloud_functions/cloud_functions.dart';

/// Region where the callable Cloud Functions are actually deployed.
///
/// NOTE: `ffPrivateApiCall` is currently live in `us-central1` (Firebase's
/// default region), even though firebase/functions/index.js declares
/// `europe-west3`. Calling the wrong region returns a 404 that surfaces in the
/// client as a `FirebaseFunctionsException(code: internal)` — which is exactly
/// why Stripe Checkout failed to open. Keep this in sync with the region the
/// functions are deployed to; if you redeploy from the current source it will
/// move to europe-west3 and this must change too.
const _kCloudFunctionsRegion = 'us-central1';

Future<Map<String, dynamic>> makeCloudCall(
  String callName,
  Map<String, dynamic> input,
) async {
  try {
    final response =
        await FirebaseFunctions.instanceFor(region: _kCloudFunctionsRegion)
            .httpsCallable(callName, options: HttpsCallableOptions())
            .call(input);
    return response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : {};
  } on FirebaseFunctionsException catch (e) {
    print(
      'Cloud call error!\n ${callName}'
      'Code: ${e.code}\n'
      'Details: ${e.details}\n'
      'Message: ${e.message}',
    );
  } catch (e) {
    print('Cloud call error:${callName} $e');
  }
  return {};
}
