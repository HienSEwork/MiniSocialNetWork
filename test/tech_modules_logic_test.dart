import 'package:flutter_test/flutter_test.dart';

import 'package:tech_net_mobile/data/models/ai_prompt_models.dart';
import 'package:tech_net_mobile/data/models/gear_price_models.dart';
import 'package:tech_net_mobile/data/models/hardware_models.dart';
import 'package:tech_net_mobile/data/models/trivia_models.dart';

void main() {
  HardwareComponent component({
    required String id,
    required String type,
    String? socket,
    int power = 0,
    int psu = 0,
    double price = 100,
  }) => HardwareComponent(
    id: id,
    type: type,
    name: id,
    brand: 'TechNet',
    socket: socket,
    powerWatt: power,
    psuWatt: psu,
    price: price,
    specs: const {},
    isActive: true,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test('PC compatibility accepts matching socket and 25% PSU headroom', () {
    final selected = {
      'CPU': component(id: 'cpu', type: 'CPU', socket: 'AM5', power: 100),
      'MAINBOARD': component(
        id: 'board',
        type: 'MAINBOARD',
        socket: 'AM5',
        power: 40,
      ),
      'RAM': component(id: 'ram', type: 'RAM', power: 10),
      'GPU': component(id: 'gpu', type: 'GPU', power: 200),
      'PSU': component(id: 'psu', type: 'PSU', psu: 500),
      'CASE': component(id: 'case', type: 'CASE', power: 5),
    };

    final result = PcCompatibilityEngine.evaluate(selected);

    expect(result.totalWatt, 355);
    expect(result.requiredPsuWatt, 444);
    expect(result.isComplete, isTrue);
    expect(result.isCompatible, isTrue);
    expect(result.errors, isEmpty);
  });

  test('PC compatibility reports socket and insufficient PSU errors', () {
    final selected = {
      'CPU': component(id: 'cpu', type: 'CPU', socket: 'AM5', power: 120),
      'MAINBOARD': component(
        id: 'board',
        type: 'MAINBOARD',
        socket: 'LGA1700',
        power: 40,
      ),
      'RAM': component(id: 'ram', type: 'RAM', power: 10),
      'GPU': component(id: 'gpu', type: 'GPU', power: 300),
      'PSU': component(id: 'psu', type: 'PSU', psu: 500),
      'CASE': component(id: 'case', type: 'CASE', power: 5),
    };

    final result = PcCompatibilityEngine.evaluate(selected);

    expect(result.requiredPsuWatt, 594);
    expect(result.isCompatible, isFalse);
    expect(result.errors, hasLength(2));
  });

  test('streak continues on the next day and resets after a gap', () {
    final next = QuestStreakCalculator.nextStreak(
      lastCompletedDate: '2026-07-20',
      completedAt: DateTime(2026, 7, 21, 22),
      currentStreak: 4,
    );
    final reset = QuestStreakCalculator.nextStreak(
      lastCompletedDate: '2026-07-18',
      completedAt: DateTime(2026, 7, 21),
      currentStreak: 4,
    );

    expect(next, 5);
    expect(reset, 1);
  });

  test(
    'depreciation applies age before condition and yields ordered ranges',
    () {
      final estimate = GearDepreciationEngine.estimate(
        msrp: 10000000,
        annualDepreciation: .2,
        releaseDate: DateTime(2025, 1, 1),
        conditionPercent: 80,
        now: DateTime(2026, 1, 1),
      );

      expect(estimate.currentValue, closeTo(6400000, 20000));
      expect(estimate.buyLow, lessThan(estimate.buyHigh));
      expect(estimate.buyHigh, lessThan(estimate.sellHigh));
    },
  );

  test('prompt engine extracts unique variables and fills known values', () {
    const template =
        'Viết về {keyword} theo {style}; nhắc lại {keyword} với giọng {tone}.';

    expect(PromptTemplateEngine.variables(template), [
      'keyword',
      'style',
      'tone',
    ]);
    expect(
      PromptTemplateEngine.build(template, {
        'keyword': 'AI riêng tư',
        'style': 'checklist',
        'tone': 'thẳng thắn',
      }),
      'Viết về AI riêng tư theo checklist; nhắc lại AI riêng tư với giọng thẳng thắn.',
    );
  });
}
