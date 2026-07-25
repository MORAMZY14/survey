import 'package:block_survey/models/internet_box_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Internet-box photo marker survives Firebase serialization', () {
    const plan = InternetBoxPlan(
      mountingArea: 'Main entrance',
      notes: 'Mount above the left-side conduit.',
      markerX: 0.25,
      markerY: 0.72,
      photoUrl: 'https://example.test/mounting-point.jpg',
      photoStoragePath: 'block_surveys/user/survey/mounting-point.jpg',
    );

    final restored = InternetBoxPlan.fromMap(plan.toMap());

    expect(restored.mountingArea, plan.mountingArea);
    expect(restored.notes, plan.notes);
    expect(restored.markerX, plan.markerX);
    expect(restored.markerY, plan.markerY);
    expect(restored.photoUrl, plan.photoUrl);
    expect(restored.photoStoragePath, plan.photoStoragePath);
  });
}
