import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/compile_result.dart';
import 'models/compiler_info.dart';

/// A client for interacting with the Wandbox API.
class WandboxClient {
  final String _baseUrl;
  final http.Client _httpClient;

  /// Creates a new Wandbox API client.
  ///
  /// [baseUrl] is the base URL of the Wandbox API. Defaults to 'https://wandbox.org/api'.
  /// [httpClient] is an optional HTTP client to use for requests.
  WandboxClient({
    String baseUrl = 'https://wandbox.org/api',
    http.Client? httpClient,
  }) : _baseUrl = baseUrl,
       _httpClient = httpClient ?? http.Client();

  /// Fetches the list of available compilers from the Wandbox API.
  ///
  /// Returns a list of [CompilerInfo] objects.
  /// Throws an exception if the API request fails.
  Future<List<CompilerInfo>> getCompilerList() async {
    final response = await _httpClient.get(Uri.parse('$_baseUrl/list.json'));

    if (response.statusCode == 200) {
      final List<dynamic> compilersJson = jsonDecode(response.body);
      return compilersJson.map((json) => CompilerInfo.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load compiler list: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Compiles and runs code on Wandbox.
  ///
  /// [compiler] is the name of the compiler to use (e.g., 'gcc-head').
  /// [code] is the source code to compile and run.
  /// [stdin] is optional input to provide to the program.
  /// [options] are compiler-specific options.
  /// [compilerOptionsRaw] are raw compiler options.
  /// [runtimeOptionsRaw] are raw runtime options.
  /// [codes] is a list of additional source files. Each map should have 'file' and 'code' keys.
  /// [save] determines if a permanent link should be created.
  ///
  /// Returns a [CompileResult] object.
  /// Throws an exception if the API request fails.
  Future<CompileResult> compile({
    required String compiler,
    required String code,
    String? stdin,
    String? options,
    String? compilerOptionsRaw,
    String? runtimeOptionsRaw,
    List<Map<String, String>>? codes,
    bool save = false,
  }) async {
    final headers = {'Content-Type': 'application/json; charset=utf-8'};
    final body = <String, dynamic>{
      'compiler': compiler,
      'code': code,
      'save': save,
    };

    if (stdin != null) body['stdin'] = stdin;
    if (options != null) body['options'] = options;
    if (compilerOptionsRaw != null) {
      body['compiler-option-raw'] = compilerOptionsRaw;
    }
    if (runtimeOptionsRaw != null) {
      body['runtime-option-raw'] = runtimeOptionsRaw;
    }
    if (codes != null) body['codes'] = codes;

    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/compile.json'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return CompileResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to compile: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Fetches the result from a permanent link.
  ///
  /// [link] is the permanent link ID.
  /// Returns a map containing the permalink data.
  /// Throws an exception if the API request fails.
  Future<Map<String, dynamic>> getPermlink(String link) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/permlink/$link'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed to load permlink: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Closes the HTTP client.
  ///
  /// This should be called when the client is no longer needed.
  void close() {
    _httpClient.close();
  }
}
