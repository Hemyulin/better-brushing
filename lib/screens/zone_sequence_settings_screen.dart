import 'package:flutter/material.dart';

import '../controllers/app_settings_controller.dart';
import '../l10n/l10n.dart';
import '../models/brushing_zone.dart';

class ZoneSequenceSettingsScreen extends StatefulWidget {
  const ZoneSequenceSettingsScreen({
    super.key,
    required this.settingsController,
  });

  final AppSettingsController settingsController;

  @override
  State<ZoneSequenceSettingsScreen> createState() =>
      _ZoneSequenceSettingsScreenState();
}

class _ZoneSequenceSettingsScreenState
    extends State<ZoneSequenceSettingsScreen> {
  late List<BrushingZone> _draftOrder;

  @override
  void initState() {
    super.initState();
    _draftOrder = List<BrushingZone>.of(
      widget.settingsController.settings.zoneOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settingsController,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.zoneSequenceTitle)),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 0.86,
                    child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      children: [
                        for (final zone in BrushingZone.values)
                          _ZoneOrderBox(
                            zone: zone,
                            stepNumber: _stepNumber(zone),
                            onTap: () => _toggleZone(zone),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _resetOrder,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(context.l10n.zoneSequenceReset),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int? _stepNumber(BrushingZone zone) {
    final index = _draftOrder.indexOf(zone);
    return index == -1 ? null : index + 1;
  }

  Future<void> _toggleZone(BrushingZone zone) async {
    final selectedIndex = _draftOrder.indexOf(zone);
    setState(() {
      if (selectedIndex == -1) {
        _draftOrder.add(zone);
      } else {
        _draftOrder = _draftOrder.take(selectedIndex).toList();
      }
    });

    if (_draftOrder.length == BrushingZone.values.length) {
      await widget.settingsController.update(
        widget.settingsController.settings.copyWith(
          zoneOrder: List<BrushingZone>.of(_draftOrder),
        ),
      );
    }
  }

  void _resetOrder() {
    setState(() {
      _draftOrder = <BrushingZone>[];
    });
  }
}

class _ZoneOrderBox extends StatelessWidget {
  const _ZoneOrderBox({
    required this.zone,
    required this.stepNumber,
    required this.onTap,
  });

  final BrushingZone zone;
  final int? stepNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = stepNumber != null;

    return Material(
      color: selected ? const Color(0xFF49B7A5) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2C2A4A)
                  : const Color(0xFFEDE7DA),
              width: selected ? 3 : 2,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: selected
                      ? CircleAvatar(
                          key: ValueKey(stepNumber),
                          radius: 28,
                          backgroundColor: const Color(0xFF2C2A4A),
                          child: Text(
                            '$stepNumber',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        )
                      : const Icon(
                          Icons.add_circle_outline_rounded,
                          key: ValueKey('empty'),
                          size: 50,
                          color: Color(0xFF5D5A88),
                        ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      context.l10n.zoneName(zone),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF2C2A4A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
