import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wandbox_dart/wandbox_dart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wandbox Flutter Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends HookWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final client = useMemoized(() => WandboxClient());
    final compilers = useState<List<CompilerInfo>>([]);
    final selectedCompiler = useState<String?>(null);
    final code = useState<String>(
        '#include <iostream>\nint main() { std::cout << "Hello, Wandbox!" << std::endl; return 0; }');
    final result = useState<CompileResult?>(null);
    final isLoading = useState<bool>(false);
    final error = useState<String?>(null);

    final codeController = useTextEditingController(text: code.value);

    useEffect(() {
      codeController.addListener(() {
        code.value = codeController.text;
      });
      return () => codeController.removeListener(() {
            code.value = codeController.text;
          });
    }, [codeController]);

    useEffect(() {
      isLoading.value = true;
      client.getCompilerList().then((value) {
        compilers.value = value;
        if (value.isNotEmpty) {
          // Select a C++ compiler by default if available
          final cppCompiler = value.firstWhere(
            (c) =>
                c.language.toLowerCase().contains('c++') &&
                !c.name.toLowerCase().contains('boost') &&
                !c.name.toLowerCase().contains('experimental') &&
                !c.name.toLowerCase().contains(
                    'concepts') && // often not default-constructible friendly
                !c.name.toLowerCase().contains('modules'), // same as above
            orElse: () => value.firstWhere(
                (c) => c.language.toLowerCase().contains('c++'),
                orElse: () => value.first),
          );
          selectedCompiler.value = cppCompiler.name;
        }
      }).catchError((e) {
        error.value = 'Failed to load compilers: $e';
      }).whenComplete(() => isLoading.value = false);
      return client.close; // Close the client when the widget is disposed
    }, [client]);

    void compileAndRun() async {
      if (selectedCompiler.value == null) {
        error.value = 'Please select a compiler.';
        return;
      }
      isLoading.value = true;
      error.value = null;
      result.value = null;
      try {
        final res = await client.compile(
          compiler: selectedCompiler.value!,
          code: code.value,
          save: true, // Save to get a permlink
        );
        result.value = res;
      } catch (e) {
        error.value = 'Error: $e';
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wandbox Flutter Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            if (error.value != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  error.value!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (compilers.value.isEmpty &&
                isLoading.value &&
                selectedCompiler.value ==
                    null) // Show main loading indicator only on initial load
              const Center(
                  child: CircularProgressIndicator(key: Key('initialLoader')))
            else if (compilers.value.isNotEmpty)
              DropdownButtonFormField<String>(
                key: const Key('compilerDropdown'),
                decoration: const InputDecoration(
                  labelText: 'Select Compiler',
                  border: OutlineInputBorder(),
                ),
                value: selectedCompiler.value,
                items: compilers.value
                    .map((compiler) => DropdownMenuItem(
                          value: compiler.name,
                          child: Text(
                              '${compiler.displayName ?? compiler.name} (${compiler.version}) - ${compiler.language}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedCompiler.value = value;
                },
              ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('codeInput'),
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Enter your code',
                border: OutlineInputBorder(),
              ),
              maxLines: 10,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('compileButton'),
              onPressed: isLoading.value ? null : compileAndRun,
              child: isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, key: Key('compileLoader')))
                  : const Text('Compile and Run'),
            ),
            const SizedBox(height: 16),
            if (result.value != null)
              Card(
                key: const Key('resultCard'),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${result.value?.status ?? "N/A"}',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (result.value?.compilerMessage?.isNotEmpty ?? false)
                        SelectableText(
                            'Compiler Message:\n${result.value?.compilerMessage}',
                            key: const Key('compilerMessage')),
                      if (result.value?.programMessage?.isNotEmpty ?? false)
                        SelectableText(
                            'Program Message:\n${result.value?.programMessage}',
                            key: const Key('programMessage')),
                      if (result.value?.signal?.isNotEmpty ?? false)
                        SelectableText('Signal: ${result.value?.signal}',
                            key: const Key('signalMessage')),
                      if (result.value?.permlink?.isNotEmpty ?? false)
                        SelectableText('Permlink: ${result.value?.permlink}',
                            key: const Key('permlink')),
                      if (result.value?.url?.isNotEmpty ?? false)
                        SelectableText('URL: ${result.value?.url}',
                            key: const Key('url')),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
