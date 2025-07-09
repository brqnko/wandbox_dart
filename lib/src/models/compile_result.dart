/// Represents the result of a compilation request to the Wandbox API.
class CompileResult {
  /// The status code of the compilation (e.g., 0 for success).
  final String? status;

  /// The compiler output (stdout).
  final String? compilerOutput;

  /// The compiler error output (stderr).
  final String? compilerError;

  /// A combined message from compiler output and error.
  final String? compilerMessage;

  /// The program output (stdout).
  final String? programOutput;

  /// The program error output (stderr).
  final String? programError;

  /// A combined message from program output and error.
  final String? programMessage;

  /// The signal received by the program, if any (e.g., "SIGSEGV").
  final String? signal;

  /// The permanent link to the result, if created.
  final String? permlink;

  /// The URL to the result, if a permanent link was created.
  final String? url;

  /// Creates a [CompileResult] from a JSON map.
  CompileResult.fromJson(Map<String, dynamic> json)
    : status = json['status']?.toString(),
      compilerOutput = json['compiler_output'],
      compilerError = json['compiler_error'],
      compilerMessage = json['compiler_message'],
      programOutput = json['program_output'],
      programError = json['program_error'],
      programMessage = json['program_message'],
      signal = json['signal'],
      permlink = json['permlink'],
      url = json['url'];

  /// Converts this [CompileResult] to a JSON map.
  Map<String, dynamic> toJson() => {
    'status': status,
    'compiler_output': compilerOutput,
    'compiler_error': compilerError,
    'compiler_message': compilerMessage,
    'program_output': programOutput,
    'program_error': programError,
    'program_message': programMessage,
    'signal': signal,
    'permlink': permlink,
    'url': url,
  };

  @override
  String toString() {
    return 'CompileResult(status: $status, programMessage: $programMessage, compilerMessage: $compilerMessage)';
  }
}
