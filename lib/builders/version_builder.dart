// ignore_for_file: depend_on_referenced_packages

import 'package:build/build.dart';
import 'package:glob/glob.dart';

Builder versionBuilder(BuilderOptions _) => const _VersionBuilder();

class _VersionBuilder implements Builder {
  const _VersionBuilder();

  @override
  Map<String, List<String>> get buildExtensions => const {
    r'$lib$': ['version.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final pubspecIds = await buildStep
        .findAssets(Glob('pubspec.yaml'))
        .toList();
    if (pubspecIds.isEmpty) {
      throw StateError(
        'version_builder: pubspec.yaml not found in build graph',
      );
    }

    final text = await buildStep.readAsString(pubspecIds.first);
    final name =
        _match(text, RegExp(r'^name:\s*(\S+)', multiLine: true)) ?? 'app';
    final version =
        _match(text, RegExp(r'^version:\s*(\S+)', multiLine: true)) ?? '0.0.0';

    final output =
        '''
const String appVersion = '$version';

const String appRelease = '$name@$version';
''';

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'lib/version.g.dart'),
      output,
    );
  }

  String? _match(String text, RegExp regex) {
    final m = regex.firstMatch(text);
    return m?.group(1);
  }
}
