import 'package:flutter/services.dart';

/// The one native channel the integrity layer speaks over.
///
/// `installId` and `attest` are answered by the same platform code — `IntegrityChannel`
/// on iOS, `MainActivity` on Android — so the name is declared once here instead of as a
/// string literal at each end, where the two could drift apart and only fail at runtime.
const MethodChannel integrityChannel = MethodChannel('stingers/integrity');
