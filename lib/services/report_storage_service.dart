import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

class StoredReport {
  StoredReport({
    required this.id,
    required this.title,
    required this.type,
    required this.filename,
    required this.createdAt,
    required this.entryCount,
    required this.insight,
    required this.samples,
  });

  final String id;
  final String title;
  final String type;
  final String filename;
  final DateTime createdAt;
  final int entryCount;
  final String insight;
  final List<Map<String, dynamic>> samples;

  factory StoredReport.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt = data['createdAt'];
    final rawSamples = data['samples'];

    return StoredReport(
      id: doc.id,
      title: data['title'] ?? 'Health Report',
      type: data['type'] ?? 'report',
      filename: data['filename'] ?? '${doc.id}.pdf',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      entryCount: (data['entryCount'] ?? 0) as int,
      insight: data['insight'] ?? 'No insight available',
      samples: rawSamples is List
          ? rawSamples
                .whereType<Map>()
                .map((sample) => _sampleFromFirestore(sample))
                .toList()
          : [],
    );
  }

  static Map<String, dynamic> _sampleFromFirestore(Map sample) {
    final time = sample['time'];

    return {
      'bpm': sample['bpm'] ?? 0,
      'spo2': sample['spo2'] ?? 0,
      'temp': sample['temp'] ?? 0,
      'gesture': sample['gesture'] ?? 0,
      'fall': sample['fall'] ?? 0,
      'battery': sample['battery'] ?? 0,
      'time': time is Timestamp ? time.toDate() : DateTime.now(),
    };
  }
}

class ReportStorageService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = AuthService();

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Please login before saving reports.');
    }
    return uid;
  }

  Stream<List<StoredReport>> watchReports() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(StoredReport.fromDoc).toList());
  }

  Future<StoredReport> saveReport({
    required String title,
    required String type,
    required int entryCount,
    required String insight,
    required List<Map<String, dynamic>> data,
  }) async {
    final userId = _uid;
    final reportRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('reports')
        .doc();
    final createdAt = DateTime.now();
    final filename = _filename(type, createdAt);
    final samples = _compactSamples(data);

    await reportRef
        .set({
          'title': title,
          'type': type,
          'filename': filename,
          'entryCount': entryCount,
          'insight': insight,
          'samples': samples,
          'createdAt': Timestamp.fromDate(createdAt),
        })
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException(
              'Report save timed out. Check Firestore setup and internet.',
            );
          },
        );

    return StoredReport(
      id: reportRef.id,
      title: title,
      type: type,
      filename: filename,
      createdAt: createdAt,
      entryCount: entryCount,
      insight: insight,
      samples: samples.map(StoredReport._sampleFromFirestore).toList(),
    );
  }

  Future<void> deleteReport(StoredReport report) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('reports')
        .doc(report.id)
        .delete()
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException(
              'Report delete timed out. Check Firestore setup and internet.',
            );
          },
        );
  }

  List<Map<String, dynamic>> _compactSamples(List<Map<String, dynamic>> data) {
    const maxSamples = 600;
    final step = data.length <= maxSamples
        ? 1
        : (data.length / maxSamples).ceil();

    return [
      for (var index = 0; index < data.length; index += step)
        {
          'bpm': data[index]['bpm'] ?? 0,
          'spo2': data[index]['spo2'] ?? 0,
          'temp': data[index]['temp'] ?? 0,
          'gesture': data[index]['gesture'] ?? 0,
          'fall': data[index]['fall'] ?? 0,
          'battery': data[index]['battery'] ?? 0,
          'time': Timestamp.fromDate(
            (data[index]['time'] ?? DateTime.now()) as DateTime,
          ),
        },
    ];
  }

  String _filename(String type, DateTime time) {
    final stamp =
        '${time.year}${_two(time.month)}${_two(time.day)}_${_two(time.hour)}${_two(time.minute)}';
    final safeType = type.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return 'kinesentry_${safeType}_$stamp.pdf';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
