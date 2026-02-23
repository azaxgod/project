import 'dart:html' as html;
import 'dart:typed_data';

String? downloadFileWeb(List<int> bytes, String filename, String extension) {
  try {
    final blob = html.Blob([Uint8List.fromList(bytes)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', '$filename.$extension')
      ..click();
    html.Url.revokeObjectUrl(url);
    return null;
  } catch (e) {
    return null;
  }
}

