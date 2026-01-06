import "dart:io";

import "package:intl/intl.dart";
import "package:xml/xml.dart";

const platformList = ["ios", "android", "ohos", "macos", "windows", "linux"];
final String version = Platform.environment["VERSION_NAME"] ?? "0.0.1";
final String releaseNotes = Platform.environment["RELEASE_BODY"] ?? "";
final String releaseUrl = Platform.environment["RELEASE_URL"] ?? "";
final String publishedAt = Platform.environment["PUBLISHED_AT"] ?? "";
final String outputPath =
    Platform.environment["OUTPUT_PATH"] ?? "./appcast.xml";

Future<void> main() async {
  final pubDate = formatRFC822Date(
    publishedAt.isNotEmpty ? DateTime.parse(publishedAt) : DateTime.now(),
  );
  final builder = XmlBuilder();
  builder.processing("xml", 'version="1.0" encoding="UTF-8"');
  builder.element(
    "rss",
    attributes: {
      "xmlns:sparkle": "http://www.andymatuschak.org/xml-namespaces/sparkle",
      "version": "2.0",
    },
    nest: () {
      builder.element(
        "channel",
        nest: () {
          builder.element("title", nest: "Certimate Version");
          for (final platform in platformList) {
            builder.element(
              "item",
              nest: () {
                builder.element("title", nest: "Version $version");
                builder.element(
                  "description",
                  nest: () {
                    builder.cdata(
                      releaseNotes.isNotEmpty
                          ? releaseNotes
                          : "Version $version",
                    );
                  },
                );
                builder.element("pubDate", nest: pubDate);
                builder.element(
                  "enclosure",
                  attributes: {
                    "url": releaseUrl,
                    "sparkle:version": version,
                    "sparkle:os": platform,
                  },
                );
              },
            );
          }
        },
      );
    },
  );
  final xmlDocument = builder.buildDocument();
  final outputFile = File(outputPath);
  // 确保父目录存在
  if (!await outputFile.parent.exists()) {
    await outputFile.parent.create(recursive: true);
  }
  await outputFile.writeAsString(xmlDocument.toXmlString());
}

String formatRFC822Date(DateTime date) {
  final rfc822Format = DateFormat("EEE, dd MMM yyyy HH:mm:ss '+0000'", "en_US");
  return rfc822Format.format(date.toUtc());
}
