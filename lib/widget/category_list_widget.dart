import 'package:flutter/material.dart';
import '../database/database_helper_1.dart';

class CategoryListWidget extends StatelessWidget {
  final List<CategoryInfo> categoryList;
  final int? selectedCategoryId;
  final void Function(int?) onSelectCategory;

  CategoryListWidget({
    required this.categoryList,
    this.selectedCategoryId,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categoryList.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCategoryListItem(CategoryInfo(id: null, name: 'Genel'));
          }
          final category = categoryList[index - 1];
          return _buildCategoryListItem(category);
        },
      ),
    );
  }

  Widget _buildCategoryListItem(CategoryInfo category) {
    bool isSelected = category.id == selectedCategoryId;
    return GestureDetector(
      onTap: () => onSelectCategory(category.id),
      child: Container(
        width: 120, // Sabit genişlik
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [Colors.blue.shade300, Colors.blue.shade900]
                : [Colors.grey.shade300, Colors.grey.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            category.name,
            overflow: TextOverflow.ellipsis, // Taşan metni keser
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
