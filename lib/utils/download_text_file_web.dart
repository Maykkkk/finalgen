import 'dart:convert';
import 'dart:html' as html;

Future<bool> downloadTextFile({
  required String filename,
  required String text,
}) async {
  final bytes = utf8.encode(text);
  final blob = html.Blob([bytes], 'text/plain;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return true;
}
