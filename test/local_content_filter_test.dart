import 'package:flutter_test/flutter_test.dart';
import 'package:tech_net_mobile/data/local/local_content_filter.dart';

void main() {
  const filter = LocalContentFilter();

  test('allows normal technical discussion', () {
    expect(
      filter.isAllowed('Mình vừa tối ưu SQLite index cho feed Flutter.'),
      isTrue,
    );
  });

  test('blocks content close to a prohibited sample', () {
    expect(filter.isAllowed('spam quảng cáo kiếm tiền nhanh'), isFalse);
  });
}
