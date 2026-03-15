import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/scan_session.dart';
import 'ar_overlay_service.dart';
import 'beauty_models.dart';

import 'package:flutter/material.dart';

class BeautyTryOnWidget extends StatefulWidget {
  const BeautyTryOnWidget({
    super.key,
    required this.analysis,
    required this.session,
  });

  final BeautyAnalysisResult analysis;
  final ArTryOnSession session;

  @override
  State<BeautyTryOnWidget> createState() => _BeautyTryOnWidgetState();
}

class _TryOnOption {
  const _TryOnOption({
    required this.name,
    required this.blend,
    required this.badge,
  });

  final String name;
  final Color blend;
  final String badge;
}

class _BeautyTryOnWidgetState extends State<BeautyTryOnWidget> {
  late BeautyProductCategory _selectedCategory;
  late Map<BeautyProductCategory, int> _selectedOptionIndex;
  late Map<BeautyProductCategory, List<_TryOnOption>> _optionsByCategory;

  @override
  void initState() {
    super.initState();

    final categories = widget.analysis.recommendations
        .map((r) => r.category)
        .toSet()
        .toList();

    _selectedCategory = categories.isNotEmpty
        ? categories.first
        : BeautyProductCategory.makeup;

    _optionsByCategory = {
      for (final category in BeautyProductCategory.values)
        category: _buildOptionsForCategory(category),
    };

    _selectedOptionIndex = {
      for (final category in BeautyProductCategory.values) category: 0,
    };
  }

  List<_TryOnOption> _buildOptionsForCategory(BeautyProductCategory category) {
    switch (category) {
      case BeautyProductCategory.makeup:
        return const [
          _TryOnOption(
            name: 'Soft Natural',
            blend: Color(0x55D8B59C),
            badge: 'Day',
          ),
          _TryOnOption(
            name: 'Warm Glam',
            blend: Color(0x66C78664),
            badge: 'Evening',
          ),
          _TryOnOption(
            name: 'Bold Bronze',
            blend: Color(0x779A5C3C),
            badge: 'Event',
          ),
        ];
      case BeautyProductCategory.lashes:
        return const [
          _TryOnOption(
            name: 'Natural Lift',
            blend: Color(0x66000000),
            badge: 'Light',
          ),
          _TryOnOption(
            name: 'Wispy Cat-eye',
            blend: Color(0x88000000),
            badge: 'Medium',
          ),
          _TryOnOption(
            name: 'Volume Fan',
            blend: Color(0xAA000000),
            badge: 'Bold',
          ),
        ];
      case BeautyProductCategory.nails:
        return const [
          _TryOnOption(
            name: 'Nude Gloss',
            blend: Color(0x77E3BFA9),
            badge: 'Classic',
          ),
          _TryOnOption(
            name: 'Rose Gel',
            blend: Color(0x88D38FA0),
            badge: 'Chic',
          ),
          _TryOnOption(
            name: 'Ruby Shine',
            blend: Color(0x99A64545),
            badge: 'Statement',
          ),
        ];
      case BeautyProductCategory.skincare:
        return const [
          _TryOnOption(
            name: 'Hydra Glow',
            blend: Color(0x33F7D7B5),
            badge: 'Glow',
          ),
          _TryOnOption(
            name: 'Glass Skin',
            blend: Color(0x44FFE9CC),
            badge: 'Dewy',
          ),
          _TryOnOption(
            name: 'Soft Matte Prep',
            blend: Color(0x339A7C66),
            badge: 'Matte',
          ),
        ];
    }
  }

  Color _currentBlend() {
    final options = _optionsByCategory[_selectedCategory] ?? const [];
    if (options.isEmpty) {
      return const Color(0x00000000);
    }
    final selected = _selectedOptionIndex[_selectedCategory] ?? 0;
    return options[selected.clamp(0, options.length - 1)].blend;
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = ScanSession.imageBytes;
    final options = _optionsByCategory[_selectedCategory] ?? const [];
    final selectedIndex = (_selectedOptionIndex[_selectedCategory] ?? 0)
        .clamp(0, options.isEmpty ? 0 : options.length - 1);

    final availableCategories = widget.analysis.recommendations
        .map((r) => r.category)
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0E6),
        elevation: 0,
        title: Text(
          'Beauty Try-On',
          style: FlutterFlowTheme.of(context).titleLarge.override(
                font: const TextStyle(
                  fontFamily: 'Times New Roman MT',
                  fontWeight: FontWeight.w700,
                ),
                color: const Color(0xFF3B2F2F),
                letterSpacing: 0.0,
              ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE3D1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Preview mode: this simulates looks using your selfie/photo. '
                  'Connect Banuba/ModiFace SDK to enable live face-tracked AR overlays.',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Poppins',
                        color: const Color(0xFF5C4033),
                        letterSpacing: 0.0,
                      ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 390,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE3D1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFE5CDAF),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (imageBytes != null)
                                Image.memory(imageBytes, fit: BoxFit.cover)
                              else
                                const ColoredBox(
                                  color: Color(0xFFF7EFE3),
                                  child: Center(
                                    child: Icon(
                                      Icons.face_retouching_natural,
                                      color: Color(0xFFB78466),
                                      size: 54,
                                    ),
                                  ),
                                ),
                              Container(color: _currentBlend()),
                              _FaceOverlayGuide(category: _selectedCategory),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xAA3B2F2F),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${widget.session.provider.toUpperCase()} Session',
                                    style: FlutterFlowTheme.of(context).labelSmall.override(
                                          fontFamily: 'Poppins',
                                          color: Colors.white,
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Choose Category',
                        style: FlutterFlowTheme.of(context).titleMedium.override(
                              fontFamily: 'Times New Roman MT',
                              color: const Color(0xFF3B2F2F),
                              letterSpacing: 0.0,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableCategories.map((category) {
                          final selected = category == _selectedCategory;
                          return ChoiceChip(
                            label: Text(category.label),
                            selected: selected,
                            onSelected: (_) {
                              setState(() => _selectedCategory = category);
                            },
                            selectedColor: const Color(0xFFB78466),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : const Color(0xFF5C4033),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: const Color(0xFFF7EFE3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(color: Color(0xFFE5CDAF)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Look Options',
                        style: FlutterFlowTheme.of(context).titleMedium.override(
                              fontFamily: 'Times New Roman MT',
                              color: const Color(0xFF3B2F2F),
                              letterSpacing: 0.0,
                            ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 126,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: options.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final option = options[index];
                            final isSelected = index == selectedIndex;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedOptionIndex[_selectedCategory] = index);
                              },
                              child: Container(
                                width: 150,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFB78466)
                                      : const Color(0xFFEDE3D1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFB78466)
                                        : const Color(0xFFE5CDAF),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: option.blend,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0x66FFFFFF),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      option.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                            fontFamily: 'Poppins',
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF3B2F2F),
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      option.badge,
                                      style: FlutterFlowTheme.of(context).labelSmall.override(
                                            fontFamily: 'Poppins',
                                            color: isSelected
                                                ? const Color(0xFFF7EFE3)
                                                : const Color(0xFF8B6A52),
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tip: once AR SDK is connected, these selections will map to live tracked overlays from `${widget.session.provider}`.',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Poppins',
                              color: const Color(0xFF8B6A52),
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB78466),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check_rounded),
            label: Text(
              'Done',
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    fontFamily: 'Perandory SemiCondensed',
                    color: Colors.white,
                    letterSpacing: 0.0,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FaceOverlayGuide extends StatelessWidget {
  const _FaceOverlayGuide({required this.category});

  final BeautyProductCategory category;

  @override
  Widget build(BuildContext context) {
    switch (category) {
      case BeautyProductCategory.makeup:
      case BeautyProductCategory.skincare:
        return Align(
          alignment: Alignment.center,
          child: Container(
            width: 230,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(140),
              border: Border.all(color: const Color(0x66FFFFFF), width: 1.2),
            ),
          ),
        );
      case BeautyProductCategory.lashes:
        return Align(
          alignment: const Alignment(0, -0.25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _lashGuide(),
              const SizedBox(width: 22),
              _lashGuide(),
            ],
          ),
        );
      case BeautyProductCategory.nails:
        return Align(
          alignment: const Alignment(0.85, 0.8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              4,
              (_) => Container(
                width: 16,
                height: 24,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xAAFFFFFF)),
                ),
              ),
            ),
          ),
        );
    }
  }

  Widget _lashGuide() {
    return Container(
      width: 58,
      height: 14,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xCCFFFFFF), width: 2),
        ),
      ),
    );
  }
}
