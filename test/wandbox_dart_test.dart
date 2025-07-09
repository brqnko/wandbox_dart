import 'package:test/test.dart';
import 'package:wandbox_dart/wandbox_dart.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'dart:convert';

// Mock data based on actual API responses
// Ensure newlines within JSON string values are escaped as \n
const mockCompilerListJson = '''
[
  {
    "compiler-option-raw": true,
    "display-compile-command": "g++ prog.cpp -Wall -Wextra -std=c++2a -O2 -DONLINE_JUDGE -I/opt/boost/gcc/include -L/opt/boost/gcc/lib",
    "display-name": "GCC HEAD",
    "language": "C++",
    "name": "gcc-head",
    "provider": 0,
    "runtime-option-raw": true,
    "switches": [
      {
        "default": true,
        "name": "cpp-verbose",
        "display-flags": "-v",
        "display-name": "Verbose output"
      }
    ],
    "templates": ["cpp", "cpp-hello-world"],
    "version": "14.0.1 20240519 (experimental)"
  },
  {
    "compiler-option-raw": true,
    "display-compile-command": "clang++ prog.cpp -Wall -Wextra -std=c++2b -O2 -DONLINE_JUDGE -I/opt/boost/clang/include -L/opt/boost/clang/lib",
    "display-name": "Clang HEAD",
    "language": "C++",
    "name": "clang-head",
    "provider": 1,
    "runtime-option-raw": true,
    "switches": [],
    "templates": ["cpp", "cpp-hello-world"],
    "version": "19.0.0 (https://github.com/llvm/llvm-project.git 22247c03983f5b3669150a2953f76e1047a70ba2)"
  },
  {
    "compiler-option-raw": false,
    "display-compile-command": "python prog.py",
    "display-name": "CPython",
    "language": "Python",
    "name": "cpython-3.12.3",
    "provider": 0,
    "runtime-option-raw": true,
    "switches": [],
    "templates": ["python"],
    "version": "3.12.3"
  }
]
''';

const mockCompileResultJson = '''
{
  "status": "0",
  "compiler_output": null,
  "compiler_error": null,
  "compiler_message": "",
  "program_output": "Hello, Wandbox!\\n",
  "program_error": null,
  "program_message": "Hello, Wandbox!\\n",
  "permlink": "abcdef123456",
  "url": "https://wandbox.org/permlink/abcdef123456",
  "signal": null
}
''';

const mockPermlinkResultJson = '''
{
  "parameter": {
    "compiler": "gcc-head",
    "code": "#include <iostream>\\nint main() { std::cout << \\"Hello, Wandbox!\\" << std::endl; }",
    "save": true
  },
  "results": [
    {"type": "Control", "data": "Finish"},
    {"type": "StdOut", "data": "Hello, Wandbox!\\n"},
    {"type": "ExitCode", "data": "0"}
  ]
}
''';

void main() {
  group('WandboxClient', () {
    late WandboxClient client;
    late http_testing.MockClient mockHttpClient;

    setUp(() {
      mockHttpClient = http_testing.MockClient((request) async {
        if (request.url.path.endsWith('/list.json')) {
          return http.Response(mockCompilerListJson, 200,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }
        if (request.url.path.endsWith('/compile.json')) {
          final body = jsonDecode(request.body);
          expect(body['compiler'], isA<String>());
          expect(body['code'], isA<String>());
          return http.Response(mockCompileResultJson, 200,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }
        if (request.url.path.startsWith('/api/permlink/')) {
          // Adjusted to match client's URL construction
          return http.Response(mockPermlinkResultJson, 200,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return http.Response('Not Found: ${request.url.path}', 404);
      });
      client = WandboxClient(httpClient: mockHttpClient);
    });

    tearDown(() {
      client.close();
    });

    test('getCompilerList returns a list of CompilerInfo', () async {
      final compilers = await client.getCompilerList();
      expect(compilers, isA<List<CompilerInfo>>());
      expect(compilers.length, 3);
      expect(compilers[0].name, 'gcc-head');
      expect(compilers[0].language, 'C++');
      expect(compilers[0].version, '14.0.1 20240519 (experimental)');
      expect(compilers[1].name, 'clang-head');
      expect(compilers[2].name, 'cpython-3.12.3');
      expect(compilers[2].language, 'Python');
    });

    test('getCompilerList throws an exception on API error', () async {
      mockHttpClient = http_testing.MockClient((request) async {
        return http.Response('Server error', 500);
      });
      client = WandboxClient(httpClient: mockHttpClient);
      expect(client.getCompilerList(), throwsException);
    });

    test('compile returns a CompileResult', () async {
      final result =
          await client.compile(compiler: 'gcc-head', code: 'dummy code');
      expect(result, isA<CompileResult>());
      expect(result.status, '0');
      expect(result.programOutput, 'Hello, Wandbox!\n');
      expect(result.programMessage, 'Hello, Wandbox!\n');
      expect(result.permlink, 'abcdef123456');
      expect(result.url, 'https://wandbox.org/permlink/abcdef123456');
      expect(result.compilerMessage, "");
    });

    test('compile sends correct parameters', () async {
      mockHttpClient = http_testing.MockClient((request) async {
        if (request.url.path.endsWith('/compile.json')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['compiler'], 'test-compiler');
          expect(body['code'], 'test code');
          expect(body['stdin'], 'test stdin');
          expect(body['options'], 'test options');
          expect(body['compiler-option-raw'], 'test compiler-options');
          expect(body['runtime-option-raw'], 'test runtime-options');
          expect(body['codes'], [
            {'file': 'f.cc', 'code': 'int a;'}
          ]);
          expect(body['save'], true);
          return http.Response(mockCompileResultJson, 200,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return http.Response('Not Found', 404);
      });
      client = WandboxClient(httpClient: mockHttpClient);

      await client.compile(
        compiler: 'test-compiler',
        code: 'test code',
        stdin: 'test stdin',
        options: 'test options',
        compilerOptionsRaw: 'test compiler-options',
        runtimeOptionsRaw: 'test runtime-options',
        codes: [
          {'file': 'f.cc', 'code': 'int a;'}
        ],
        save: true,
      );
      // Assertions are in the mock client
    });

    test('compile throws an exception on API error', () async {
      mockHttpClient = http_testing.MockClient((request) async {
        if (request.url.path.endsWith('/compile.json')) {
          return http.Response('Server error', 500);
        }
        return http.Response('Not Found', 404);
      });
      client = WandboxClient(httpClient: mockHttpClient);
      expect(client.compile(compiler: 'gcc-head', code: 'dummy code'),
          throwsException);
    });

    test('getPermlink returns a map', () async {
      final result = await client.getPermlink(
          'someId'); // The mock is set for '/api/permlink/someId' effectively
      expect(result, isA<Map<String, dynamic>>());
      expect(result['parameter']['compiler'], 'gcc-head');
      expect(result['parameter']['code'],
          '#include <iostream>\nint main() { std::cout << "Hello, Wandbox!" << std::endl; }');
      expect(result['results'][1]['data'], "Hello, Wandbox!\n");
    });

    test('getPermlink throws an exception on API error', () async {
      mockHttpClient = http_testing.MockClient((request) async {
        return http.Response('Server error', 500);
      });
      client = WandboxClient(httpClient: mockHttpClient);
      expect(client.getPermlink('someId'), throwsException);
    });
  });

  group('CompilerInfo', () {
    test('fromJson creates a valid CompilerInfo object from real API data', () {
      final json = jsonDecode(mockCompilerListJson)[0] as Map<String, dynamic>;
      final compilerInfo = CompilerInfo.fromJson(json);
      expect(compilerInfo.name, "gcc-head");
      expect(compilerInfo.version, "14.0.1 20240519 (experimental)");
      expect(compilerInfo.language, "C++");
      expect(compilerInfo.displayName, "GCC HEAD");
      expect(compilerInfo.templates, equals(["cpp", "cpp-hello-world"]));
      expect(compilerInfo.warning, isNull);
      expect(compilerInfo.provider, 0);
    });

    test('toJson converts CompilerInfo object to valid JSON', () {
      final compilerInfo = CompilerInfo.fromJson(
          jsonDecode(mockCompilerListJson)[0] as Map<String, dynamic>);
      final jsonOutput = compilerInfo.toJson();
      expect(jsonOutput['name'], "gcc-head");
      expect(jsonOutput['version'], "14.0.1 20240519 (experimental)");
      expect(jsonOutput['language'], "C++");
      expect(jsonOutput['display-name'], "GCC HEAD");
      expect(jsonOutput['templates'], equals(["cpp", "cpp-hello-world"]));
      expect(jsonOutput['warning'], isNull);
      expect(jsonOutput['provider'], 0);
    });
  });

  group('CompileResult', () {
    test('fromJson creates a valid CompileResult object from real API data',
        () {
      final json = jsonDecode(mockCompileResultJson) as Map<String, dynamic>;
      final compileResult = CompileResult.fromJson(json);
      expect(compileResult.status, "0");
      expect(compileResult.compilerOutput, isNull);
      expect(compileResult.compilerError, isNull);
      expect(compileResult.compilerMessage, "");
      expect(compileResult.programOutput, "Hello, Wandbox!\n");
      expect(compileResult.programError, isNull);
      expect(compileResult.programMessage, "Hello, Wandbox!\n");
      expect(compileResult.signal, isNull);
      expect(compileResult.permlink, "abcdef123456");
      expect(compileResult.url, "https://wandbox.org/permlink/abcdef123456");
    });

    test('toJson converts CompileResult object to valid JSON', () {
      final compileResult = CompileResult.fromJson(
          jsonDecode(mockCompileResultJson) as Map<String, dynamic>);
      final jsonOutput = compileResult.toJson();
      expect(jsonOutput['status'], "0");
      expect(jsonOutput['compiler_output'], isNull);
      expect(jsonOutput['compiler_error'], isNull);
      expect(jsonOutput['compiler_message'], "");
      expect(jsonOutput['program_output'], "Hello, Wandbox!\n");
      expect(jsonOutput['program_error'], isNull);
      expect(jsonOutput['program_message'], "Hello, Wandbox!\n");
      expect(jsonOutput['signal'], isNull);
      expect(jsonOutput['permlink'], "abcdef123456");
      expect(jsonOutput['url'], "https://wandbox.org/permlink/abcdef123456");
    });
  });
}
