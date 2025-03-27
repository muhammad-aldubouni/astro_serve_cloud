import 'dart:math';

import 'package:server_nano/server_nano.dart';
import 'package:archive/archive.dart';
import 'dart:io';

void main(List<String> args) async {
  final server = Server();

  server.get("/state", (req, res) => res.send("running ..."));

  server.post("/upload", (req, res) async {
    res.setHeader("Access-Control-Allow-Origin", "*");
    bool large = false;
    String siteName = "non";
    if (req.isFormData) {
      if (req.isMultipart) {
        Map<dynamic, dynamic>? data = await req.payload();
        data?.values.forEach((ele) {
          if (ele is MultipartUpload) {
            if (ele.bytes.length > (1024 * 1024 * 10)) {
              res.status(400);
              res.send("large_file_size.html");
              large = true;
              return;
            }
            print(ele.name);
            siteName =
                ele.name?.replaceAll('.zip', "") ??
                "${Random().nextInt(1000000000)}";
            siteName = 'cloud/$siteName${Random().nextInt(99999999)}';
            siteName += setupSite(ele, siteName);
          }
        });

        if (large) return;
        if (siteName.endsWith('no_index.html')) {
          res.status(400);
          res.send('no_index.html');
          return;
        }

        if (siteName.endsWith('error.html')) {
          res.status(400);
          res.send('error.html');
          return;
        }
        res.send(siteName);
      }
    }
  });
  server.static('astro_serve', jail: false);
  //server.static('astro_serve/sites', jail: false);
  server.listen(host: '0.0.0.0', port: 8080);
}

String setupSite(MultipartUpload upload, String siteName) {
  late final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(upload.bytes);
  } catch (e) {
    return "error.html";
  }
  String url = "";
  for (final file in archive) {
    if (file.isFile) {
      print(file.name);
      if (file.name.endsWith("index.html") || file.name.endsWith("index.htm")) {
        url = file.name;
      }
      File('astro_serve/$siteName/${file.name}')
        ..createSync(recursive: true)
        ..writeAsBytesSync(file.content);
    }
  }

  if (url != "" ||
      url.endsWith("index.html") ||
      url.endsWith("index.htm")) //uploaded sccessfully
  {
    url = url.replaceAll("index.html", '').replaceAll('index.htm', '');
    if (url.endsWith("/")) url = url.substring(0, url.length - 1);

    return url != "" ? '/$url' : url;
  }

  // free space of uploaded site
  try {
    Directory('astro_serve/$siteName').delete(recursive: true);
  } catch (e) {
    logger(e.toString());
  }
  return 'no_index.html';
}
