import 'dart:math';

import 'package:server_nano/server_nano.dart';
import 'package:archive/archive.dart';
import 'dart:io';

void main(List<String> args) async {
  final server = Server();

  server.get("/state", (req, res) => res.send("running ..."));

  server.post("/upload", (req, res) async {
    String siteName = "non";
    if (req.isFormData) {
      if (req.isMultipart) {
        Map<dynamic, dynamic>? data = await req.payload();
        data?.values.forEach((ele) {
          if (ele is MultipartUpload) {
            print(ele.name);
            siteName =
                ele.name?.replaceAll('.zip', "") ??
                "${Random().nextInt(1000000000)}";
            siteName = 'sites/$siteName${Random().nextInt(99999999)}';
            decompressZip(ele, siteName);
          }
        });
        res.setHeader("Access-Control-Allow-Origin", "*");
        res.send('$siteName/index.html');
      }
    }
  });
  server.static('astro_serve', jail: false);
  //server.static('astro_serve/sites', jail: false);
  server.listen(host: '0.0.0.0', port: 8080);
}

void decompressZip(MultipartUpload upload, String siteName) {
  final archive = ZipDecoder().decodeBytes(upload.bytes);
  for (final file in archive) {
    if (file.isFile) {
      print(file.name);
      File('astro_serve/$siteName/${file.name}')
        ..createSync(recursive: true)
        ..writeAsBytesSync(file.content);
    }
  }
}
