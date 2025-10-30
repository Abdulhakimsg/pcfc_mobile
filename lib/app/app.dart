import 'package:flutter/material.dart';
import 'theme.dart';
import '../features/home/presentation/home_page.dart';

class OnePassApp extends StatelessWidget {
  const OnePassApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'OnePass Demo',
        theme: AppTheme.material,
        home: const HomePage(),
      );
}