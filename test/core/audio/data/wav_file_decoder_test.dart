import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/data/wav_file_decoder.dart';
import 'package:picturestovideos/core/audio/domain/audio_import_failure.dart';

void main() {
  group('WavFileDecoder', () {
    test('decodes 16-bit mono PCM WAV bytes', () {
      const decoder = WavFileDecoder();
      final wavBytes = _buildWavFile(
        channelCount: 1,
        sampleRate: 4,
        bitsPerSample: 16,
        samples: const [0, 16384, -16384, 32767],
      );

      final audioData = decoder.decode(bytes: wavBytes);

      expect(audioData.sampleRate, 4);
      expect(audioData.channelCount, 1);
      expect(audioData.samples.length, 4);
      expect(audioData.samples[0], closeTo(0, 0.0001));
      expect(audioData.samples[1], closeTo(0.5, 0.0001));
      expect(audioData.samples[2], closeTo(-0.5, 0.0001));
      expect(audioData.samples[3], closeTo(0.9999, 0.0002));
      expect(audioData.duration, const Duration(seconds: 1));
    });

    test('mixes stereo PCM WAV data down to mono samples', () {
      const decoder = WavFileDecoder();
      final wavBytes = _buildWavFile(
        channelCount: 2,
        sampleRate: 2,
        bitsPerSample: 16,
        samples: const [32767, -32768, 16384, 16384],
      );

      final audioData = decoder.decode(bytes: wavBytes);

      expect(audioData.samples.length, 2);
      expect(audioData.samples[0], closeTo(0, 0.0002));
      expect(audioData.samples[1], closeTo(0.5, 0.0001));
    });

    test('throws for non-WAV bytes', () {
      const decoder = WavFileDecoder();

      expect(
        () => decoder.decode(bytes: Uint8List.fromList(List.filled(64, 0))),
        throwsA(
          isA<AudioImportException>().having(
            (exception) => exception.failure.type,
            'type',
            AudioImportFailureType.invalidFormat,
          ),
        ),
      );
    });
  });
}

Uint8List _buildWavFile({
  required int channelCount,
  required int sampleRate,
  required int bitsPerSample,
  required List<int> samples,
}) {
  final bytesPerSample = bitsPerSample ~/ 8;
  final dataSize = samples.length * bytesPerSample;
  final byteData = ByteData(44 + dataSize);

  _writeAscii(byteData, 0, 'RIFF');
  byteData.setUint32(4, 36 + dataSize, Endian.little);
  _writeAscii(byteData, 8, 'WAVE');
  _writeAscii(byteData, 12, 'fmt ');
  byteData.setUint32(16, 16, Endian.little);
  byteData.setUint16(20, 1, Endian.little);
  byteData.setUint16(22, channelCount, Endian.little);
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(
    28,
    sampleRate * channelCount * bytesPerSample,
    Endian.little,
  );
  byteData.setUint16(32, channelCount * bytesPerSample, Endian.little);
  byteData.setUint16(34, bitsPerSample, Endian.little);
  _writeAscii(byteData, 36, 'data');
  byteData.setUint32(40, dataSize, Endian.little);

  var offset = 44;
  for (final sample in samples) {
    byteData.setInt16(offset, sample, Endian.little);
    offset += 2;
  }

  return byteData.buffer.asUint8List();
}

void _writeAscii(ByteData data, int offset, String value) {
  for (var index = 0; index < value.length; index++) {
    data.setUint8(offset + index, value.codeUnitAt(index));
  }
}
