// ==============================================================================
// LEGALMETRY — Commodity Category Selection Screen (Screen B2 / Module 1.3d)
// Track 2: Capture & Ingest (Person 2)
//
// Governing Standard: GIGW 3.0 / UI Design Context Document B2
// Digitizes statutory commodity categories from the Legal Metrology Rules, 2011.
// feeds the Category-Aware Verification Router (Sixth Schedule).
// ==============================================================================

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../capture/camera_screen.dart';

class CategoryItem {
  final String id;
  final String title;
  final String titleHindi;
  final String description;
  final IconData icon;
  final String scheduleReference;

  const CategoryItem({
    required this.id,
    required this.title,
    required this.titleHindi,
    required this.description,
    required this.icon,
    this.scheduleReference = 'First Schedule / Second Schedule',
  });
}

class CategorySelectorScreen extends StatefulWidget {
  const CategorySelectorScreen({super.key});

  @override
  State<CategorySelectorScreen> createState() => _CategorySelectorScreenState();
}

class _CategorySelectorScreenState extends State<CategorySelectorScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isHindi = false;
  String _searchQuery = '';

  static const List<CategoryItem> _categories = [
    CategoryItem(
      id: 'edible_oils',
      title: 'Edible Oils & Vanaspati',
      titleHindi: 'खाद्य तेल एवं वनस्पति',
      description: 'Must declare net quantity in volume (ml/l) or weight (g/kg) with gross density cross-check.',
      icon: Icons.water_drop_outlined,
      scheduleReference: 'Rule 12 & Sixth Schedule',
    ),
    CategoryItem(
      id: 'biscuits_bakery',
      title: 'Biscuits, Bread & Confectionery',
      titleHindi: 'बिस्कुट, ब्रेड एवं कन्फेक्शनरी',
      description: 'Standard pack size verification (Second Schedule) and unit sale price display.',
      icon: Icons.cookie_outlined,
      scheduleReference: 'Second Schedule, Item 4',
    ),
    CategoryItem(
      id: 'packaged_water',
      title: 'Packaged Drinking Water & Beverages',
      titleHindi: 'पैकेज्ड पेयजल एवं शीतल पेय',
      description: 'Mandatory standard sizes: 200ml, 250ml, 500ml, 1L, 2L, 5L.',
      icon: Icons.local_drink_outlined,
      scheduleReference: 'Second Schedule, Item 12',
    ),
    CategoryItem(
      id: 'tea_coffee',
      title: 'Tea & Coffee',
      titleHindi: 'चाय एवं कॉफी',
      description: 'Standardized mass packaging: 25g, 50g, 100g, 250g, 500g, 1kg.',
      icon: Icons.coffee_outlined,
      scheduleReference: 'Second Schedule, Item 2',
    ),
    CategoryItem(
      id: 'dairy_products',
      title: 'Milk Powder, Butter & Dairy',
      titleHindi: 'दूध पाउडर, मक्खन एवं डेयरी उत्पाद',
      description: 'Requires net weight declaration, moisture tolerance check, and best before date.',
      icon: Icons.egg_outlined,
      scheduleReference: 'First Schedule',
    ),
    CategoryItem(
      id: 'pulses_cereals',
      title: 'Pulses, Cereals & Food Grains',
      titleHindi: 'दालें, अनाज एवं खाद्यान्न',
      description: 'Standardized 500g, 1kg, 2kg, 5kg packaging sizes and net quantity tolerance.',
      icon: Icons.grain_outlined,
      scheduleReference: 'Second Schedule, Item 1',
    ),
    CategoryItem(
      id: 'cement_building',
      title: 'Cement & Building Materials',
      titleHindi: 'सीमेंट एवं निर्माण सामग्री',
      description: 'Standard 50kg bags; gross/tare tolerance and statutory batch coding.',
      icon: Icons.construction_outlined,
      scheduleReference: 'Rule 27 & Sixth Schedule',
    ),
    CategoryItem(
      id: 'detergents_soaps',
      title: 'Soaps, Detergents & Cleaning',
      titleHindi: 'साबुन, डिटर्जेंट एवं सफाई उत्पाद',
      description: 'Toilet soaps must state TFM grade and weight at packing.',
      icon: Icons.soap_outlined,
      scheduleReference: 'First Schedule',
    ),
    CategoryItem(
      id: 'paints_varnishes',
      title: 'Paints, Enamels & Varnishes',
      titleHindi: 'पेंट, एनामेल एवं वार्निश',
      description: 'Standard packaging in 50ml, 100ml, 200ml, 500ml, 1L, 4L, 10L, 20L.',
      icon: Icons.format_paint_outlined,
      scheduleReference: 'Second Schedule, Item 9',
    ),
    CategoryItem(
      id: 'packaged_spices',
      title: 'Spices & Condiments',
      titleHindi: 'मसाले एवं खाद्य सामग्री',
      description: 'Standard sizes: 50g, 100g, 200g, 500g, 1kg with Table I font rules.',
      icon: Icons.restaurant_outlined,
      scheduleReference: 'Second Schedule, Item 15',
    ),
    CategoryItem(
      id: 'cosmetics_toiletries',
      title: 'Cosmetics & Personal Care',
      titleHindi: 'सौंदर्य प्रसाधन एवं व्यक्तिगत देखभाल',
      description: 'MRP, batch, use-before date and manufacturer contact verification.',
      icon: Icons.face_retouching_natural_outlined,
      scheduleReference: 'Rule 6 & Rule 8',
    ),
    CategoryItem(
      id: 'general_packaged',
      title: 'General Packaged Commodity',
      titleHindi: 'सामान्य पैकेज्ड वस्तु',
      description: 'Standard Rule 6 declarations and Table I font dimensions inspection.',
      icon: Icons.inventory_2_outlined,
      scheduleReference: 'Legal Metrology Rules, 2011',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredCategories = _categories.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.title.toLowerCase().contains(query) ||
          c.titleHindi.contains(query) ||
          c.description.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isHindi ? 'कमोडिटी श्रेणी चुनें' : 'Select Commodity Category',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _isHindi = !_isHindi),
            icon: const Icon(Icons.translate, color: Colors.white, size: 18),
            label: Text(
              _isHindi ? 'EN' : 'हिन्दी',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: _isHindi ? 'श्रेणी खोजें...' : 'Search statutory categories...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryNavy),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Category List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              itemCount: filteredCategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing8),
              itemBuilder: (context, index) {
                final cat = filteredCategories[index];
                return _buildCategoryTile(context, cat, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, CategoryItem cat, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CameraScreen(category: cat.title),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: AppTheme.cardDecoration(isDark: isDark),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(cat.icon, color: AppTheme.secondaryBlue, size: 24),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isHindi ? cat.titleHindi : cat.title,
                    style: AppTheme.headingSmall.copyWith(
                      color: isDark ? Colors.white : AppTheme.primaryNavy,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(cat.description, style: AppTheme.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    cat.scheduleReference,
                    style: AppTheme.caption.copyWith(fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
