import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../domain/recipe.dart';

class RecipeSummaryTile extends StatelessWidget {
  final Recipe recipe;
  final String? subtitle;
  final VoidCallback onTap;

  const RecipeSummaryTile({
    super.key,
    required this.recipe,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: RecipeThumbnail(recipe: recipe),
      title: Text(recipe.name),
      subtitle: subtitle == null || subtitle!.isEmpty ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class RecipeThumbnail extends StatelessWidget {
  final Recipe recipe;
  final double size;

  const RecipeThumbnail({super.key, required this.recipe, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    final image = recipe.displayImage;

    if (image.isEmpty) {
      return _placeholder(const Icon(Icons.restaurant, size: 24));
    }

    if (image.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            _placeholder(const Icon(Icons.image, size: 24)),
        errorWidget: (context, url, error) =>
            _placeholder(const Icon(Icons.image, size: 24)),
      );
    }

    final file = File(image);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }

    return _placeholder(const Icon(Icons.broken_image, size: 24));
  }

  Widget _placeholder(Widget icon) {
    return Container(color: Colors.grey[200], child: icon);
  }
}
