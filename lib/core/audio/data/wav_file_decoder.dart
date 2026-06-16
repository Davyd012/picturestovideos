import 'dart:typed_data';

import 'package:picturestovideos/core/audio/domain/audio_data.dart';
import 'package:picturestovideos/core/audio/domain/audio_import_failure.dart';

class WavFileDecoder {
  const WavFileDecoder();

  AudioData decode({required Uint8List bytes}) {
    if (bytes.length < 44) {
      throw const AudioImportException(
        AudioImportFailure(
          type: AudioImportFailureType.corruptFile,
          message: 'WAV file is too small to contain a valid header.',
        ),
      );
    }

    final byteData = ByteData.sublistView(bytes);
    if (_readChunkId(bytes, 0) != 'RIFF' || _readChunkId(bytes, 8) != 'WAVE') {
      throw const AudioImportException(
        AudioImportFailure(
          type: AudioImportFailureType.invalidFormat,
          message: 'Only RIFF/WAVE audio files are supported.',
        ),
      );
    }

    var offset = 12;
    int? channelCount;
    int? sampleRate;
    int? bitsPerSample;
    int? audioFormat;
    Uint8List? sampleBytes;

    while (offset + 8 <= bytes.length) {
      final chunkId = _readChunkId(bytes, offset);
      final chunkSize = byteData.getUint32(offset + 4, Endian.little);
      final chunkDataOffset = offset + 8;
      final paddedChunkSize = chunkSize.isOdd ? chunkSize + 1 : chunkSize;
      final nextOffset = chunkDataOffset + paddedChunkSize;

      if (nextOffset > bytes.length) {
        throw const AudioImportException(
          AudioImportFailure(
            type: AudioImportFailureType.corruptFile,
            message: 'WAV chunk extends past the end of the file.',
          ),
        );
      }

      if (chunkId == 'fmt ') {
        if (chunkSize < 16) {
          throw const AudioImportException(
            AudioImportFailure(
              type: AudioImportFailureType.corruptFile,
              message: 'WAV fmt chunk is incomplete.',
            ),
          );
        }

        audioFormat = byteData.getUint16(chunkDataOffset, Endian.little);
        channelCount = byteData.getUint16(chunkDataOffset + 2, Endian.little);
        sampleRate = byteData.getUint32(chunkDataOffset + 4, Endian.little);
        bitsPerSample = byteData.getUint16(chunkDataOffset + 14, Endian.little);
      } else if (chunkId == 'data') {
        sampleBytes = Uint8List.sublistView(
          bytes,
          chunkDataOffset,
          chunkDataOffset + chunkSize,
        );
      }

      offset = nextOffset;
    }

    if (audioFormat == null ||
        channelCount == null ||
        sampleRate == null ||
        bitsPerSample == null ||
        sampleBytes == null) {
      throw const AudioImportException(
        AudioImportFailure(
          type: AudioImportFailureType.corruptFile,
          message: 'WAV file is missing format or sample data chunks.',
        ),
      );
    }

    final samples = _decodeSamples(
      audioFormat: audioFormat,
      bitsPerSample: bitsPerSample,
      channelCount: channelCount,
      sampleBytes: sampleBytes,
    );

    final durationMicros =
        (samples.length * Duration.microsecondsPerSecond) ~/ sampleRate;

    return AudioData(
      samples: samples,
      sampleRate: sampleRate,
      duration: Duration(microseconds: durationMicros),
      channelCount: channelCount,
    );
  }

  String _readChunkId(Uint8List bytes, int offset) {
    return String.fromCharCodes(bytes.sublist(offset, offset + 4));
  }

  List<double> _decodeSamples({
    required int audioFormat,
    required int bitsPerSample,
    required int channelCount,
    required Uint8List sampleBytes,
  }) {
    final bytesPerSample = bitsPerSample ~/ 8;
    if (bytesPerSample == 0) {
      throw const AudioImportException(
        AudioImportFailure(
          type: AudioImportFailureType.corruptFile,
          message: 'Invalid bits-per-sample value in WAV header.',
        ),
      );
    }

    final frameSize = bytesPerSample * channelCount;
    if (frameSize == 0 || sampleBytes.length % frameSize != 0) {
      throw const AudioImportException(
        AudioImportFailure(
          type: AudioImportFailureType.corruptFile,
          message: 'WAV sample data does not align with the frame size.',
        ),
      );
    }

    if (audioFormat != 1 && audioFormat != 3) {
      throw AudioImportException(
        AudioImportFailure(
          type: AudioImportFailureType.unsupportedFormat,
          message: 'WAV audio format $audioFormat is not supported.',
        ),
      );
    }

    final sampleData = ByteData.sublistView(sampleBytes);
    final frameCount = sampleBytes.length ~/ frameSize;
    final samples = List<double>.filled(frameCount, 0.0);

    for (var frameIndex = 0; frameIndex < frameCount; frameIndex++) {
      final frameOffset = frameIndex * frameSize;
      var mixedSample = 0.0;

      for (var channelIndex = 0; channelIndex < channelCount; channelIndex++) {
        final sampleOffset = frameOffset + (channelIndex * bytesPerSample);
        mixedSample += _readSample(
          sampleData: sampleData,
          offset: sampleOffset,
          audioFormat: audioFormat,
          bitsPerSample: bitsPerSample,
        );
      }

      samples[frameIndex] = mixedSample / channelCount;
    }

    return samples;
  }

  double _readSample({
    required ByteData sampleData,
    required int offset,
    required int audioFormat,
    required int bitsPerSample,
  }) {
    if (audioFormat == 3 && bitsPerSample == 32) {
      return sampleData.getFloat32(offset, Endian.little).clamp(-1.0, 1.0);
    }

    switch (bitsPerSample) {
      case 8:
        return (sampleData.getUint8(offset) - 128) / 128;
      case 16:
        return sampleData.getInt16(offset, Endian.little) / 32768;
      case 24:
        return _readSigned24(sampleData, offset) / 8388608;
      case 32:
        return sampleData.getInt32(offset, Endian.little) / 2147483648;
      default:
        throw AudioImportException(
          AudioImportFailure(
            type: AudioImportFailureType.unsupportedFormat,
            message: 'Unsupported WAV bit depth: $bitsPerSample.',
          ),
        );
    }
  }

  int _readSigned24(ByteData sampleData, int offset) {
    final value =
        sampleData.getUint8(offset) |
        (sampleData.getUint8(offset + 1) << 8) |
        (sampleData.getUint8(offset + 2) << 16);

    return value & 0x800000 != 0 ? value | ~0xFFFFFF : value;
  }
}
