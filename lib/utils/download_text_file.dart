import 'download_text_file_stub.dart'
    if (dart.library.html) 'download_text_file_web.dart' as impl;

Future<bool> downloadTextFile({
  required String filename,
  required String text,
}) {
  return impl.downloadTextFile(
    filename: filename,
    text: text,
  );
}
