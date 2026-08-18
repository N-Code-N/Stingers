/// Tells a transport failure apart from a programming error, on whichever platform
/// this is compiled for.
///
/// `package:http` already normalises most failures into `ClientException`, but on native
/// platforms a TLS or socket error can still escape as a raw `dart:io` exception — and
/// `dart:io` does not exist on the web. The conditional import keeps that knowledge in
/// one place instead of leaking `dart:io` into the API client.
library;

export 'transport_error_io.dart' if (dart.library.js_interop) 'transport_error_web.dart';
