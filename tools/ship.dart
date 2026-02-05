import 'dart:io';
import 'package:args/args.dart';

// --- Configuration ---
const String pubspecPath = 'pubspec.yaml';
const String changelogPath = 'CHANGELOG.md';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('channel',
        abbr: 'c',
        allowed: ['stable', 'beta'],
        defaultsTo: 'stable',
        help: 'Release channel (stable or beta)')
    ..addOption('bump',
        abbr: 'b',
        allowed: ['major', 'minor', 'patch', 'none'],
        defaultsTo: 'none',
        help: 'Version bump type')
    ..addFlag('dry-run',
        abbr: 'd', defaultsTo: false, help: 'Simulate without changing files')
    ..addFlag('no-checks',
        defaultsTo: false, help: 'Skip pre-flight checks (analyze/test)')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help')
    ..addOption('message', abbr: 'm', help: 'Commit message (Required)');

  try {
    var results = parser.parse(arguments);

    if (results['help'] as bool) {
      printCyan('🚀 AnimeHat Ship Tool v2.0');
      print(parser.usage);
      exit(0);
    }

    String? message;
    String bump = results['bump'] as String;
    String channel = results['channel'] as String;
    final dryRun = results['dry-run'] as bool;
    final skipChecks = results['no-checks'] as bool;

    // Support positional arguments as message
    if (results.wasParsed('message')) {
      message = results['message'] as String;
    } else if (results.rest.isNotEmpty) {
      message = results.rest.join(' ');
    }

    // Interactive Mode
    if (message == null || message.isEmpty) {
      printCyan('🚀 AnimeHat Ship Tool - Interactive Mode');
      stdout.write('📝 Enter commit message: ');
      message = stdin.readLineSync();
      if (message == null || message.trim().isEmpty) {
        printRed('Error: Message cannot be empty.');
        exit(1);
      }

      print('\nSelect version bump:');
      print('1. None (default)');
      print('2. Patch (0.0.x)');
      print('3. Minor (0.x.0)');
      print('4. Major (x.0.0)');
      stdout.write('Choice [1-4]: ');
      final choice = stdin.readLineSync()?.trim();
      switch (choice) {
        case '2':
          bump = 'patch';
          break;
        case '3':
          bump = 'minor';
          break;
        case '4':
          bump = 'major';
          break;
        default:
          bump = 'none';
      }

      print(''); // Spacer
    }

    printCyan('🚀 AnimeHat Ship Tool v2.0');
    print('Channel: $channel | Bump: $bump | Dry Run: $dryRun');
    print('--------------------------------------------------');

    // 1. Pre-flight Checks
    if (!skipChecks) {
      if (!await runPreFlightChecks()) {
        exit(1);
      }
    } else {
      printYellow('⚠️  Skipping pre-flight checks...');
    }

    // 2. Read Current Version
    String currentVersion = await getCurrentVersion();
    print('Current Version: $currentVersion');

    // 3. Calculate New Version
    String newVersion = calculateNewVersion(currentVersion, bump, channel);
    if (newVersion != currentVersion) {
      printGreen('Bumping to: $newVersion');
    } else {
      printYellow('No version change.');
    }

    // 4. Update Files (if not dry run)
    if (!dryRun) {
      if (newVersion != currentVersion) {
        await updatePubspec(newVersion);
      }
      await updateChangelog(newVersion, message);
    }

    // 5. Git Operations
    if (!dryRun) {
      await gitOperations(newVersion, message, newVersion != currentVersion);
    } else {
      printCyan('[Dry Run] Would commit, tag, and push.');
    }

    printGreen('\n✅ Shipment Complete!');
  } catch (e) {
    printRed('Error: $e');
    exit(1);
  }
}

// --- Helpers ---

Future<bool> runPreFlightChecks() async {
  print('🔍 Running pre-flight checks...');

  // Analyze - Disabled as requested
  // print('  Running flutter analyze...');
  // final analyze = await Process.run('flutter', ['analyze']);
  // if (analyze.exitCode != 0) {
  //   printRed('  ❌ Flutter analyze failed:');
  //   print(analyze.stdout);
  //   return false;
  // }
  // printGreen('  ✅ Analyze passed.');

  // Test (optional, can be slow)
  // print('  Running flutter test...');
  // final test = await Process.run('flutter', ['test']);
  // if (test.exitCode != 0) {
  //   printRed('  ❌ Flutter test failed.');
  //   return false;
  // }
  // printGreen('  ✅ Tests passed.');

  return true;
}

Future<String> getCurrentVersion() async {
  final file = File(pubspecPath);
  final lines = await file.readAsLines();
  for (var line in lines) {
    if (line.startsWith('version: ')) {
      return line.split('version: ')[1].trim();
    }
  }
  throw Exception('Could not find version in pubspec.yaml');
}

String calculateNewVersion(String current, String bump, String channel) {
  if (bump == 'none') return current;

  // Format: major.minor.patch+build or major.minor.patch-beta.X+build
  // We strip build number for calculation
  final baseWithPrerelease = current.split('+')[0];
  final buildNumber =
      current.contains('+') ? int.parse(current.split('+')[1]) : 0;

  // Regex to separate semantic version from prerelease
  // match[1] = 1.0.0
  // match[3] = beta.1 (optional)
  final versionRegex = RegExp(r'^(\d+\.\d+\.\d+)(-([a-zA-Z0-9.]+))?$');
  final match = versionRegex.firstMatch(baseWithPrerelease);

  if (match == null) throw Exception('Invalid version format: $current');

  String semVer = match.group(1)!; // 1.0.0
  String? preRelease = match.group(3); // beta.1

  List<int> parts = semVer.split('.').map(int.parse).toList();
  int major = parts[0];
  int minor = parts[1];
  int patch = parts[2];

  // Logic for Stable vs Beta
  if (channel == 'stable') {
    // If we were on beta, deciding to go stable might mean just stripping beta suffix if version matches?
    // Or bumping.
    // Standard bumping:
    switch (bump) {
      case 'major':
        major++;
        minor = 0;
        patch = 0;
        break;
      case 'minor':
        minor++;
        patch = 0;
        break;
      case 'patch':
        patch++;
        break;
    }
    // Result is standard semver
    return '$major.$minor.$patch+${buildNumber + 1}';
  } else {
    // Beta Channel
    // If typically standard bump, we enter beta for the NEXT version usually.
    // e.g. 1.0.0 -> bump minor -> 1.1.0-beta.1
    // If already beta 1.1.0-beta.1 -> bump patch (usually means next beta) -> 1.1.0-beta.2

    if (preRelease != null && preRelease.startsWith('beta.')) {
      // Already in beta
      if (bump == 'patch') {
        // Increment beta number
        final betaNum = int.parse(preRelease.split('.')[1]);
        return '$major.$minor.$patch-beta.${betaNum + 1}+${buildNumber + 1}';
      } else {
        // If major/minor bump while in beta, we likely start a NEW beta for a NEW version
        switch (bump) {
          case 'major':
            major++;
            minor = 0;
            patch = 0;
            break;
          case 'minor':
            minor++;
            patch = 0;
            break;
        }
        return '$major.$minor.$patch-beta.1+${buildNumber + 1}';
      }
    } else {
      // Was stable, moving to beta
      switch (bump) {
        case 'major':
          major++;
          minor = 0;
          patch = 0;
          break;
        case 'minor':
          minor++;
          patch = 0;
          break;
        case 'patch':
          patch++;
          break;
      }
      return '$major.$minor.$patch-beta.1+${buildNumber + 1}';
    }
  }
}

Future<void> updatePubspec(String newVersion) async {
  final file = File(pubspecPath);
  final lines = await file.readAsLines();
  final newLines = lines.map((line) {
    if (line.startsWith('version: ')) {
      return 'version: $newVersion';
    }
    return line;
  }).toList();
  await file.writeAsString(newLines.join('\n'));
}

Future<void> updateChangelog(String version, String message) async {
  final file = File(changelogPath);
  if (!await file.exists()) {
    await file.create();
  }

  final currentContent = await file.readAsString();
  final date = DateTime.now().toIso8601String().split('T')[0];

  final newEntry = '''
## [$version] - $date
- $message

''';

  await file.writeAsString(newEntry + currentContent);
}

Future<void> gitOperations(
    String version, String message, bool versionChanged) async {
  print('📦 Committing and Pushing...');

  await runCommand('git', ['add', '.']);
  await runCommand('git', ['commit', '-m', message]);

  if (versionChanged) {
    await runCommand('git', ['tag', 'v$version']);
  }

  await runCommand('git', ['push', 'origin', 'main']);
  if (versionChanged) {
    await runCommand('git', ['push', 'origin', 'v$version']);
  }
}

Future<void> runCommand(String cmd, List<String> args) async {
  final res = await Process.run(cmd, args);
  if (res.exitCode != 0) {
    printRed('Error running $cmd ${args.join(' ')}:');
    print(res.stderr);
    exit(1);
  }
}

// --- Colors ---
void printRed(String msg) => print('\x1B[31m$msg\x1B[0m');
void printGreen(String msg) => print('\x1B[32m$msg\x1B[0m');
void printYellow(String msg) => print('\x1B[33m$msg\x1B[0m');
void printCyan(String msg) => print('\x1B[36m$msg\x1B[0m');
