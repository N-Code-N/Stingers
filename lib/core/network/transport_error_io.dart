import 'dart:io';

/// Any `IOException` escaping an HTTP call is a transport failure — a socket that would
/// not open, a TLS handshake that failed, a connection that dropped mid-response. Being
/// broad here is deliberate: the alternative is enumerating subclasses and missing one.
bool isTransportFailure(Object error) => error is IOException;
