import 'dart:math';
import 'dart:ui';
import 'game_objects.dart';
import 'scene_generator.dart';

/// The core challenge engine — procedurally generates challenges
/// Supports multiple modes: CHANGE, REMEMBER, SWAP, SEQUENCE, SPATIAL, PREDICT, HIDDEN_RULE, CHAOS
class ChallengeEngine {
  final SceneGenerator _sceneGen = SceneGenerator();
  final Random _random = Random();

  /// Generate a complete challenge with scene, modification, question, and answers
  Challenge generateChallenge({
    required ChallengeMode mode,
    required int difficulty, // 1-100+
  }) {
    switch (mode) {
      case ChallengeMode.change:
        return _generateChangeChallenge(difficulty);
      case ChallengeMode.remember:
        return _generateRememberChallenge(difficulty);
      case ChallengeMode.swap:
        return _generateSwapChallenge(difficulty);
      case ChallengeMode.sequence:
        return _generateSequenceChallenge(difficulty);
      case ChallengeMode.spatial:
        return _generateSpatialChallenge(difficulty);
      case ChallengeMode.predict:
        return _generatePredictChallenge(difficulty);
      case ChallengeMode.hiddenRule:
        return _generateHiddenRuleChallenge(difficulty);
      case ChallengeMode.chaos:
        return _generateChaosChallengeWrapped(difficulty);
    }
  }

  int _objectCountForDifficulty(int difficulty) {
    if (difficulty <= 5) return 3;
    if (difficulty <= 15) return 4;
    if (difficulty <= 30) return 5;
    if (difficulty <= 50) return 6;
    if (difficulty <= 75) return 7;
    return 8;
  }

  double _observeTimeForDifficulty(int difficulty) {
    if (difficulty <= 5) return 5.0;
    if (difficulty <= 15) return 4.0;
    if (difficulty <= 30) return 3.5;
    if (difficulty <= 50) return 3.0;
    if (difficulty <= 75) return 2.5;
    return 2.0;
  }

  // ────────── MODE B: CHANGE ──────────
  Challenge _generateChangeChallenge(int difficulty) {
    final count = _objectCountForDifficulty(difficulty);
    final originalScene = _sceneGen.generateScene(objectCount: count);

    // Pick a random change type
    final changeTypes = [ChangeType.colorChanged, ChangeType.objectRemoved, ChangeType.objectMoved];
    if (difficulty > 20) changeTypes.add(ChangeType.sizeChanged);
    final changeType = changeTypes[_random.nextInt(changeTypes.length)];

    final targetIdx = _random.nextInt(originalScene.length);
    final targetObject = originalScene[targetIdx];
    List<GameObject> modifiedScene;
    String question;
    String correctAnswer;
    List<String> wrongAnswers;

    switch (changeType) {
      case ChangeType.colorChanged:
        final availableColors = GameColors.all.where((c) => c.color.toARGB32() != targetObject.color.toARGB32()).toList();
        final newColor = availableColors[_random.nextInt(availableColors.length)];
        modifiedScene = List.from(originalScene);
        modifiedScene[targetIdx] = targetObject.copyWith(color: newColor.color);
        question = 'Which object changed color?';
        correctAnswer = targetObject.type.label;
        wrongAnswers = originalScene
            .where((o) => o.id != targetObject.id)
            .map((o) => o.type.label)
            .toSet()
            .take(3)
            .toList();
        break;

      case ChangeType.objectRemoved:
        modifiedScene = originalScene.where((o) => o.id != targetObject.id).toList();
        question = 'Which object disappeared?';
        correctAnswer = targetObject.type.label;
        wrongAnswers = originalScene
            .where((o) => o.id != targetObject.id)
            .map((o) => o.type.label)
            .toSet()
            .take(3)
            .toList();
        break;

      case ChangeType.objectMoved:
        final newPos = Offset(
          (targetObject.position.dx + 0.15 + _random.nextDouble() * 0.2).clamp(0.08, 0.92),
          (targetObject.position.dy + 0.15 + _random.nextDouble() * 0.2).clamp(0.08, 0.92),
        );
        modifiedScene = List.from(originalScene);
        modifiedScene[targetIdx] = targetObject.copyWith(position: newPos);
        question = 'Which object moved?';
        correctAnswer = targetObject.type.label;
        wrongAnswers = originalScene
            .where((o) => o.id != targetObject.id)
            .map((o) => o.type.label)
            .toSet()
            .take(3)
            .toList();
        break;

      case ChangeType.sizeChanged:
        final newSize = targetObject.size > 1.0 ? 0.6 : 1.4;
        modifiedScene = List.from(originalScene);
        modifiedScene[targetIdx] = targetObject.copyWith(size: newSize);
        question = 'Which object changed size?';
        correctAnswer = targetObject.type.label;
        wrongAnswers = originalScene
            .where((o) => o.id != targetObject.id)
            .map((o) => o.type.label)
            .toSet()
            .take(3)
            .toList();
        break;
    }

    // Ensure we have enough wrong answers
    while (wrongAnswers.length < 3) {
      final extraTypes = GameObjectType.values
          .where((t) => t.label != correctAnswer && !wrongAnswers.contains(t.label))
          .toList();
      if (extraTypes.isEmpty) break;
      wrongAnswers.add(extraTypes[_random.nextInt(extraTypes.length)].label);
    }

    // Remove duplicates of correct answer from wrong answers
    wrongAnswers = wrongAnswers.where((a) => a != correctAnswer).take(3).toList();

    final allAnswers = [correctAnswer, ...wrongAnswers]..shuffle(_random);

    return Challenge(
      mode: ChallengeMode.change,
      originalScene: originalScene,
      modifiedScene: modifiedScene,
      question: question,
      answers: allAnswers,
      correctAnswerIndex: allAnswers.indexOf(correctAnswer),
      observeTime: _observeTimeForDifficulty(difficulty),
      answerTime: 10.0,
      difficulty: difficulty,
      instruction: 'Watch carefully.',
      modeName: 'FIND THE CHANGE',
    );
  }

  // ────────── MODE A: REMEMBER ──────────
  Challenge _generateRememberChallenge(int difficulty) {
    final count = _objectCountForDifficulty(difficulty);
    final scene = _sceneGen.generateScene(objectCount: count);

    final targetIdx = _random.nextInt(scene.length);
    final target = scene[targetIdx];

    // Find a neighbor
    int nearestIdx = 0;
    double nearestDist = double.infinity;
    for (int i = 0; i < scene.length; i++) {
      if (i == targetIdx) continue;
      final dist = (scene[i].position - target.position).distance;
      if (dist < nearestDist) {
        nearestDist = dist;
        nearestIdx = i;
      }
    }
    final nearest = scene[nearestIdx];

    final colorName = GameColors.all.firstWhere(
      (c) => c.color.toARGB32() == target.color.toARGB32(),
      orElse: () => const NamedColor('the', Color(0xFFFFFFFF)),
    ).name.toLowerCase();

    final question = 'What was next to the $colorName ${target.type.label.toLowerCase()}?';
    final correctAnswer = nearest.type.label;
    final wrongAnswers = scene
        .where((o) => o.id != nearest.id && o.id != target.id)
        .map((o) => o.type.label)
        .toSet()
        .take(3)
        .toList();

    while (wrongAnswers.length < 3) {
      final extra = GameObjectType.values
          .where((t) => t.label != correctAnswer && !wrongAnswers.contains(t.label))
          .toList();
      if (extra.isEmpty) break;
      wrongAnswers.add(extra[_random.nextInt(extra.length)].label);
    }
    wrongAnswers.removeWhere((a) => a == correctAnswer);

    final allAnswers = [correctAnswer, ...wrongAnswers.take(3)]..shuffle(_random);

    return Challenge(
      mode: ChallengeMode.remember,
      originalScene: scene,
      modifiedScene: null,
      question: question,
      answers: allAnswers,
      correctAnswerIndex: allAnswers.indexOf(correctAnswer),
      observeTime: _observeTimeForDifficulty(difficulty) + 1.0,
      answerTime: 12.0,
      difficulty: difficulty,
      instruction: 'Remember everything.',
      modeName: 'REMEMBER',
    );
  }

  // ────────── MODE C: SWAP ──────────
  Challenge _generateSwapChallenge(int difficulty) {
    final count = _objectCountForDifficulty(difficulty).clamp(4, 8);
    final scene = _sceneGen.generateScene(objectCount: count);

    final indices = List.generate(scene.length, (i) => i)..shuffle(_random);
    final swapA = indices[0];
    final swapB = indices[1];

    final modifiedScene = List<GameObject>.from(scene);
    modifiedScene[swapA] = scene[swapA].copyWith(position: scene[swapB].position);
    modifiedScene[swapB] = scene[swapB].copyWith(position: scene[swapA].position);

    final correctAnswer = '${scene[swapA].type.label} & ${scene[swapB].type.label}';

    // Generate wrong swap pairs
    final wrongAnswers = <String>[];
    for (int i = 2; i < indices.length - 1 && wrongAnswers.length < 3; i += 2) {
      if (i + 1 < indices.length) {
        wrongAnswers.add('${scene[indices[i]].type.label} & ${scene[indices[i + 1]].type.label}');
      }
    }
    while (wrongAnswers.length < 3) {
      final a = GameObjectType.values[_random.nextInt(GameObjectType.values.length)];
      final b = GameObjectType.values[_random.nextInt(GameObjectType.values.length)];
      if (a != b) wrongAnswers.add('${a.label} & ${b.label}');
    }

    final allAnswers = [correctAnswer, ...wrongAnswers.take(3)]..shuffle(_random);

    return Challenge(
      mode: ChallengeMode.swap,
      originalScene: scene,
      modifiedScene: modifiedScene,
      question: 'Which two objects swapped places?',
      answers: allAnswers,
      correctAnswerIndex: allAnswers.indexOf(correctAnswer),
      observeTime: _observeTimeForDifficulty(difficulty) + 0.5,
      answerTime: 12.0,
      difficulty: difficulty,
      instruction: 'Watch closely.',
      modeName: 'SWAP',
    );
  }

  // ────────── MODE E: SEQUENCE ──────────
  Challenge _generateSequenceChallenge(int difficulty) {
    final seqLength = difficulty <= 10 ? 3 : (difficulty <= 30 ? 4 : 5);
    final colors = List<NamedColor>.from(GameColors.all)..shuffle(_random);
    final sequence = colors.take(seqLength).toList();
    
    // The answer is what comes next based on a pattern
    // Simple pattern: cycle through colors
    final nextColor = colors[seqLength % colors.length];

    // Create a "scene" from the sequence for display
    final scene = <GameObject>[];
    for (int i = 0; i < seqLength; i++) {
      scene.add(GameObject(
        id: 'seq_$i',
        type: GameObjectType.orb,
        position: Offset(0.1 + (i * 0.8 / (seqLength - 1)), 0.5),
        color: sequence[i].color,
      ));
    }

    final question = 'What comes next?';
    final correctAnswer = nextColor.name;
    final wrongAnswers = colors
        .where((c) => c.name != correctAnswer)
        .take(3)
        .map((c) => c.name)
        .toList();

    final allAnswers = [correctAnswer, ...wrongAnswers]..shuffle(_random);

    return Challenge(
      mode: ChallengeMode.sequence,
      originalScene: scene,
      modifiedScene: null,
      question: question,
      answers: allAnswers,
      correctAnswerIndex: allAnswers.indexOf(correctAnswer),
      observeTime: _observeTimeForDifficulty(difficulty) + 1.0,
      answerTime: 10.0,
      difficulty: difficulty,
      instruction: 'Find the pattern.',
      modeName: 'SEQUENCE',
    );
  }

  // ────────── MODE F: SPATIAL ──────────
  Challenge _generateSpatialChallenge(int difficulty) {
    final count = _objectCountForDifficulty(difficulty);
    final scene = _sceneGen.generateScene(objectCount: count);

    // Pick a reference point
    final refIdx = _random.nextInt(scene.length);
    final refObj = scene[refIdx];
    final refColorName = GameColors.all.firstWhere(
      (c) => c.color.toARGB32() == refObj.color.toARGB32(),
      orElse: () => const NamedColor('the', Color(0xFFFFFFFF)),
    ).name.toLowerCase();

    // Find the closest object to reference
    int closestIdx = 0;
    double closestDist = double.infinity;
    for (int i = 0; i < scene.length; i++) {
      if (i == refIdx) continue;
      final d = (scene[i].position - refObj.position).distance;
      if (d < closestDist) {
        closestDist = d;
        closestIdx = i;
      }
    }

    final question = 'Which object was closest to the $refColorName ${refObj.type.label.toLowerCase()}?';
    final correctAnswer = scene[closestIdx].type.label;
    final wrongAnswers = scene
        .where((o) => o.id != scene[closestIdx].id && o.id != refObj.id)
        .map((o) => o.type.label)
        .toSet()
        .take(3)
        .toList();

    while (wrongAnswers.length < 3) {
      final extra = GameObjectType.values
          .where((t) => t.label != correctAnswer && !wrongAnswers.contains(t.label))
          .toList();
      if (extra.isEmpty) break;
      wrongAnswers.add(extra[_random.nextInt(extra.length)].label);
    }

    final allAnswers = [correctAnswer, ...wrongAnswers.take(3)]..shuffle(_random);

    return Challenge(
      mode: ChallengeMode.spatial,
      originalScene: scene,
      modifiedScene: null,
      question: question,
      answers: allAnswers,
      correctAnswerIndex: allAnswers.indexOf(correctAnswer),
      observeTime: _observeTimeForDifficulty(difficulty) + 1.0,
      answerTime: 12.0,
      difficulty: difficulty,
      instruction: 'Study the positions.',
      modeName: 'SPATIAL',
    );
  }

  // ────────── MODE D: PREDICT ──────────
  Challenge _generatePredictChallenge(int difficulty) {
    // Show an object moving in a direction, ask where it ends up
    final count = _objectCountForDifficulty(difficulty).clamp(3, 5);
    final scene = _sceneGen.generateScene(objectCount: count);

    final movingIdx = _random.nextInt(scene.length);
    final movingObj = scene[movingIdx];

    // Determine movement direction
    final directions = ['top-left', 'top-right', 'bottom-left', 'bottom-right'];
    final direction = directions[_random.nextInt(directions.length)];

    final question = 'Where will the ${movingObj.type.label.toLowerCase()} end up?';
    final correctAnswer = direction;
    final wrongAnswers = directions.where((d) => d != correctAnswer).take(3).toList();

    final allAnswers = [correctAnswer, ...wrongAnswers]..shuffle(_random);

    // Create "modified" scene showing movement arrow
    final modifiedScene = List<GameObject>.from(scene);
    Offset endPos;
    switch (direction) {
      case 'top-left':
        endPos = const Offset(0.15, 0.15);
        break;
      case 'top-right':
        endPos = const Offset(0.85, 0.15);
        break;
      case 'bottom-left':
        endPos = const Offset(0.15, 0.85);
        break;
      default:
        endPos = const Offset(0.85, 0.85);
    }
    modifiedScene[movingIdx] = movingObj.copyWith(position: endPos);

    return Challenge(
      mode: ChallengeMode.predict,
      originalScene: scene,
      modifiedScene: modifiedScene,
      question: question,
      answers: allAnswers,
      correctAnswerIndex: allAnswers.indexOf(correctAnswer),
      observeTime: _observeTimeForDifficulty(difficulty),
      answerTime: 8.0,
      difficulty: difficulty,
      instruction: 'Predict the movement.',
      modeName: 'PREDICT',
    );
  }

  // ────────── MODE G: HIDDEN RULE ──────────
  Challenge _generateHiddenRuleChallenge(int difficulty) {
    // Show examples of a rule, ask player to identify it
    final rules = [
      _HiddenRule(
        'Circles move right',
        'What do circles do?',
        'Move right',
        ['Change color', 'Disappear', 'Grow bigger'],
      ),
      _HiddenRule(
        'Red objects disappear',
        'What happens to red objects?',
        'They disappear',
        ['They move', 'They grow', 'They change color'],
      ),
      _HiddenRule(
        'Triangles change to blue',
        'What do triangles do?',
        'Change to blue',
        ['Move up', 'Disappear', 'Rotate'],
      ),
    ];

    final rule = rules[_random.nextInt(rules.length)];
    final scene = _sceneGen.generateScene(objectCount: 4);

    final allAnswers = [rule.correctAnswer, ...rule.wrongAnswers]..shuffle(_random);

    return Challenge(
      mode: ChallengeMode.hiddenRule,
      originalScene: scene,
      modifiedScene: null,
      question: rule.question,
      answers: allAnswers,
      correctAnswerIndex: allAnswers.indexOf(rule.correctAnswer),
      observeTime: _observeTimeForDifficulty(difficulty) + 2.0,
      answerTime: 15.0,
      difficulty: difficulty,
      instruction: 'Discover the rule.',
      modeName: 'HIDDEN RULE',
    );
  }

  // ────────── MODE H: CHAOS ──────────
  Challenge _generateChaosChallengeWrapped(int difficulty) {
    // Combine random mode
    final modes = [ChallengeMode.change, ChallengeMode.remember, ChallengeMode.spatial];
    final mode = modes[_random.nextInt(modes.length)];
    final challenge = generateChallenge(mode: mode, difficulty: difficulty + 10);
    return Challenge(
      mode: ChallengeMode.chaos,
      originalScene: challenge.originalScene,
      modifiedScene: challenge.modifiedScene,
      question: challenge.question,
      answers: challenge.answers,
      correctAnswerIndex: challenge.correctAnswerIndex,
      observeTime: challenge.observeTime - 0.5,
      answerTime: challenge.answerTime - 2,
      difficulty: challenge.difficulty,
      instruction: 'Everything at once.',
      modeName: 'CHAOS',
    );
  }

  /// Get the appropriate mode for the player's current level
  ChallengeMode getModeForLevel(int level) {
    if (level <= 5) return ChallengeMode.change;
    if (level <= 15) return ChallengeMode.remember;
    if (level <= 25) return ChallengeMode.swap;
    if (level <= 35) return ChallengeMode.sequence;
    if (level <= 50) return ChallengeMode.spatial;
    if (level <= 70) return ChallengeMode.predict;
    if (level <= 90) return ChallengeMode.hiddenRule;
    return ChallengeMode.chaos;
  }

  /// Randomly pick a mode from unlocked modes for variety
  ChallengeMode getRandomUnlockedMode(int level) {
    final unlocked = <ChallengeMode>[];
    unlocked.add(ChallengeMode.change);
    if (level >= 5) unlocked.add(ChallengeMode.remember);
    if (level >= 15) unlocked.add(ChallengeMode.swap);
    if (level >= 25) unlocked.add(ChallengeMode.sequence);
    if (level >= 35) unlocked.add(ChallengeMode.spatial);
    if (level >= 50) unlocked.add(ChallengeMode.predict);
    if (level >= 70) unlocked.add(ChallengeMode.hiddenRule);
    if (level >= 90) unlocked.add(ChallengeMode.chaos);
    return unlocked[_random.nextInt(unlocked.length)];
  }
}

// ────────── Data Classes ──────────

enum ChallengeMode {
  change,
  remember,
  swap,
  sequence,
  spatial,
  predict,
  hiddenRule,
  chaos,
}

enum ChangeType {
  colorChanged,
  objectRemoved,
  objectMoved,
  sizeChanged,
}

class Challenge {
  final ChallengeMode mode;
  final List<GameObject> originalScene;
  final List<GameObject>? modifiedScene;
  final String question;
  final List<String> answers;
  final int correctAnswerIndex;
  final double observeTime; // seconds to observe original
  final double answerTime; // seconds to answer
  final int difficulty;
  final String instruction;
  final String modeName;

  const Challenge({
    required this.mode,
    required this.originalScene,
    this.modifiedScene,
    required this.question,
    required this.answers,
    required this.correctAnswerIndex,
    required this.observeTime,
    required this.answerTime,
    required this.difficulty,
    required this.instruction,
    required this.modeName,
  });

  String get correctAnswer => answers[correctAnswerIndex];
}

class _HiddenRule {
  final String description;
  final String question;
  final String correctAnswer;
  final List<String> wrongAnswers;

  const _HiddenRule(this.description, this.question, this.correctAnswer, this.wrongAnswers);
}
