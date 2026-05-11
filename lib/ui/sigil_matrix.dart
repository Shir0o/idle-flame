import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/state/game_state.dart';
import '../game/state/skill_catalog.dart';

class SigilMatrix extends StatelessWidget {
  const SigilMatrix({super.key, this.size = 300});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, _) {
        return CustomPaint(
          size: Size(size, size),
          painter: _SigilMatrixPainter(state: state),
        );
      },
    );
  }
}

class _SigilMatrixPainter extends CustomPainter {
  _SigilMatrixPainter({required this.state});
  final GameState state;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Path clusters centers
    final edgeCenter = center + const Offset(0, -1) * radius * 0.8;
    final daemonCenter =
        center +
        Offset(math.cos(7 * math.pi / 6), math.sin(7 * math.pi / 6)) *
            radius *
            0.8;
    final hexCenter =
        center +
        Offset(math.cos(11 * math.pi / 6), math.sin(11 * math.pi / 6)) *
            radius *
            0.8;

    // Draw path rings
    _drawPathRing(canvas, edgeCenter, SkillPath.edge, radius * 0.45);
    _drawPathRing(canvas, daemonCenter, SkillPath.daemon, radius * 0.4);
    _drawPathRing(canvas, hexCenter, SkillPath.hex, radius * 0.4);

    // Map archetypes to positions
    final nodePositions = <SkillArchetype, Offset>{};

    // EDGE (5 nodes)
    _layoutCluster(edgeCenter, radius * 0.25, [
      SkillArchetype.chain,
      SkillArchetype.barrage,
      SkillArchetype.sentinel,
      SkillArchetype.focus,
      SkillArchetype.rupture,
    ], nodePositions);

    // DAEMON (4 nodes)
    _layoutCluster(daemonCenter, radius * 0.2, [
      SkillArchetype.mothership,
      SkillArchetype.firewall,
      SkillArchetype.meteor,
      SkillArchetype.bounty,
    ], nodePositions);

    // HEX (4 nodes)
    _layoutCluster(hexCenter, radius * 0.2, [
      SkillArchetype.nova,
      SkillArchetype.frost,
      SkillArchetype.snake,
      SkillArchetype.summon,
    ], nodePositions);

    // Draw lines (Synergies)
    _drawSynergyLines(canvas, nodePositions);

    // Draw Nexus Core
    final corePaint = Paint()..color = state.nexusCoreColor;
    canvas.drawCircle(center, 12, corePaint);
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw Nodes
    for (final archetype in SkillArchetype.values) {
      final pos = nodePositions[archetype]!;
      final level = state.skillLevel(archetype.name);
      _drawNode(canvas, pos, archetype, level);
    }
  }

  void _layoutCluster(
    Offset center,
    double radius,
    List<SkillArchetype> items,
    Map<SkillArchetype, Offset> map,
  ) {
    for (int i = 0; i < items.length; i++) {
      final angle = (i * 2 * math.pi / items.length) - math.pi / 2;
      map[items[i]] =
          center + Offset(math.cos(angle), math.sin(angle)) * radius;
    }
  }

  void _drawPathRing(
    Canvas canvas,
    Offset center,
    SkillPath path,
    double radius,
  ) {
    final tier = state.getTier(path);
    if (tier == PathTier.none) return;

    final color = path.color;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1 + tier.index * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 + tier.index.toDouble();

    canvas.drawCircle(center, radius, paint);

    // Outer glow
    canvas.drawCircle(
      center,
      radius + 2,
      Paint()
        ..color = color.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _drawNode(
    Canvas canvas,
    Offset pos,
    SkillArchetype archetype,
    int level,
  ) {
    final color = archetype.color;
    final isOwned = level > 0;

    final paint = Paint()
      ..color = isOwned ? color : Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pos, 6, paint);

    if (isOwned) {
      // Glow
      canvas.drawCircle(
        pos,
        8,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Evolution mark
      if (state.getEvolution(archetype) > 0) {
        canvas.drawCircle(pos, 3, Paint()..color = Colors.white);
      }
    }
  }

  void _drawSynergyLines(Canvas canvas, Map<SkillArchetype, Offset> positions) {
    final synergyPairs = [
      (SkillArchetype.chain, SkillArchetype.nova),
      (SkillArchetype.mothership, SkillArchetype.summon),
      (SkillArchetype.frost, SkillArchetype.rupture),
      (SkillArchetype.meteor, SkillArchetype.firewall),
      (SkillArchetype.sentinel, SkillArchetype.barrage),
      (SkillArchetype.bounty, SkillArchetype.mothership), // One example
    ];

    for (final pair in synergyPairs) {
      final p1 = positions[pair.$1]!;
      final p2 = positions[pair.$2]!;
      final l1 = state.skillLevel(pair.$1.name);
      final l2 = state.skillLevel(pair.$2.name);

      if (l1 > 0 && l2 > 0) {
        final paint = Paint()
          ..shader = ui.Gradient.linear(p1, p2, [pair.$1.color, pair.$2.color])
          ..strokeWidth = 1.5;
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SigilMatrixPainter oldDelegate) => true;
}
