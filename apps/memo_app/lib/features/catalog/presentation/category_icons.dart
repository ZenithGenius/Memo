import 'package:flutter/material.dart';

IconData categoryIcon(String? name) => switch (name) {
      'bubble' => Icons.chat_bubble_outline,
      'hand' => Icons.back_hand_outlined,
      'plate' => Icons.restaurant_outlined,
      'face' => Icons.sentiment_satisfied_outlined,
      'cross' => Icons.local_hospital_outlined,
      'person' => Icons.person_outline,
      'house' => Icons.home_outlined,
      'drop' => Icons.water_drop_outlined,
      _ => Icons.grid_view_outlined,
    };
