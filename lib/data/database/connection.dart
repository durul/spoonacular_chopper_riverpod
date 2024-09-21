/// Connection.dart allows the code to create a connection based on whether
/// the app is running on mobile, desktop or the web.

// We use a conditional export to expose the right connection factory depending
// on the platform.

export 'unsupported.dart'
    if (dart.library.js) 'web.dart'
    if (dart.library.ffi) 'native.dart';
