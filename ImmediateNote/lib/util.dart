import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as ppath;
import 'package:hand_signature/signature.dart';

int currIdx = 0;
int greatestIdx = 0;
String pendingAct = '';
int numOfWriterPending = 0;
//Map<int, String> jsonChangeUnderway = <int, String>{};
//Map<int, int> jsonChangePendingId = <int, int>{};
HandSignatureControl control = HandSignatureControl(
  threshold: 0.01,
  smoothRatio: 0.65,
  velocityRange: 2.0,
);

ValueNotifier<String?> current = ValueNotifier<String?>(null);
Directory appDocsDir = Directory.current;

void cancelPointlessWrite() {
  if (numOfWriterPending > 1) numOfWriterPending = 1;
}

Future<void> triggerAct() async {
  if (numOfWriterPending != 0) return;
  switch (pendingAct) {
    case 'del':
      int idx = currIdx;
      if (await getJsonFile(idx).exists()) await getJsonFile(idx).delete();
      for (;;) {
        File nextf = getJsonFile(idx + 1);
        if (!await nextf.exists()) {
          break;
        }
        await nextf.rename(ppath.join(appDocsDir.path, '$idx'));
        ++idx;
      }
      if (currIdx == 1) {
        await handlePossibleZeroJson();
      } else {
        --currIdx;
        --greatestIdx;
        await readJsonFile();
      }
      break;
    case 'prev':
      if (currIdx != 1) {
        --currIdx;
      }
      await readJsonFile();
      break;
    case 'next':
      ++currIdx;
      int idx = currIdx;
      File jsonf = getJsonFile(idx);
      if (await jsonf.exists()) {
        await readJsonFile();
      } else {
        await newJsonFile(idx);
      }
      break;
    default: //should be unreachable
      throw Exception('Unexpected violation of invariant');
      break;
  }
}

Future<void> handlePossibleZeroJson() async {
  int idx = 1;
  File jsonf = getJsonFile(idx);
  if (await jsonf.exists()) {
    --greatestIdx;
    await readJsonFile();
  } else {
    await newJsonFile(idx);
  }
}

Future<void> newJsonFile(int idx) async {
  currIdx = idx;
  await getJsonFile(idx).writeAsString('');
  greatestIdx = currIdx;
  current.value = '';
}

Future<void> readJsonFile() async {
  current.value = await getJsonFile(currIdx).readAsString();
}

File getJsonFile(int idx) {
  return File(ppath.join(appDocsDir.path, '$idx'));
}

File getTmpJsonFile(int idx) {
  return File(ppath.join(appDocsDir.path, 'tmp' + idx.toString()));
}
