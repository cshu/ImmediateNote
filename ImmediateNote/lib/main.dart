import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as ppath;
import 'package:path_provider/path_provider.dart';
import 'package:hand_signature/signature.dart';

import 'util.dart';

void main() => runApp(const MyApp());

bool initialized = false;

class MyHome extends StatelessWidget {
  const MyHome({super.key});
  Widget _mainWg() {
    return ValueListenableBuilder<String?>(
      valueListenable: current,
      builder: (context, data, child) {
        if (data == null) {
          return Center(child: const Text('Loading...'));
        } else {
          control.clear();
          if (data!.isNotEmpty) control.importData(jsonDecode(data!));
          return Column(
            children: <Widget>[
              Row(children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: ElevatedButton(
                        onPressed: () async {
                          showAboutDialog(
                            context: context,
                            applicationName: 'Immediate Note',
                            applicationVersion: '1.0',
                            applicationLegalese:
                                'Copyright \u{00A9} 2023 Chang Shu\nThis program comes with absolutely no warranty.',
                          );
                        },
                        child: const Text('About')),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: ElevatedButton(
                        onPressed: () async {
                          if (current.value == null) return;
                          current.value = null;
                          cancelPointlessWrite();
                          pendingAct = 'del';
                          await triggerAct();
                        },
                        child: const Text('Delete')),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: ElevatedButton(
                        onPressed: () async {
                          if (current.value == null) return;
                          control.clear();
                          changeListener();
                        },
                        child: const Text('Clear')),
                  ),
                ),
              ]),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints.expand(),
                  color: Colors.white,
                  child: HandSignature(
                    control: control,
                    type: SignatureDrawType.shape,
                  ),
                ),
              ),
              Row(children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: ElevatedButton(
                        onPressed: () async {
                          if (current.value == null) return;
                          current.value = null;
                          pendingAct = 'prev';
                          await triggerAct();
                        },
                        child: const Text('Previous')),
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text('$currIdx/$greatestIdx')),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: ElevatedButton(
                        onPressed: () async {
                          if (current.value == null) return;
                          current.value = null;
                          pendingAct = 'next';
                          await triggerAct();
                        },
                        child: const Text('Next')),
                  ),
                ),
              ]),
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      initialized = true;
      () async {
        control.addListener(changeListener);
        appDocsDir = await getApplicationDocumentsDirectory();
        int idx = 1;
        for (;;) {
          File jsonf = getJsonFile(idx);
          if (!await jsonf.exists()) break;
          ++idx;
        }
        --idx;
        if (idx == 0) {
          await newJsonFile(1);
        } else {
          currIdx = idx;
          greatestIdx = currIdx;
          await readJsonFile();
        }
      }();
    }
    return Scaffold(
      body: SafeArea(
        child: _mainWg(),
      ),
    );
  }
}

Future<void> writeJsonFile() async {
  //print('Writing Once'); //debug
  var idx = currIdx;
  var jsondata = jsonEncode(control.toMap());
  var tmpfile = getTmpJsonFile(idx);
  await tmpfile.writeAsString(jsondata);
  await tmpfile.rename(ppath.join(appDocsDir.path, '$idx'));
}

void changeListener() {
  if (current.value == null) return;
  () async {
    switch (numOfWriterPending) {
      case 0:
        ++numOfWriterPending;
        for (;;) {
          await writeJsonFile();
          --numOfWriterPending;
          if (0 == numOfWriterPending) {
            if (null == current.value) await triggerAct();
            break;
          }
        }
        break;
      case 1:
        ++numOfWriterPending;
        break;
      default: //i.e. 2, do nothing, no need to escalate to 3, coz no difference
        break;
    }
  }();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Immediate Note',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHome());
  }
}
