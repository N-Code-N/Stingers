/// On the web every network failure already arrives as a `ClientException` from
/// `package:http`'s browser client, which the caller handles before consulting this.
/// There is nothing left for it to recognise.
bool isTransportFailure(Object error) => false;
