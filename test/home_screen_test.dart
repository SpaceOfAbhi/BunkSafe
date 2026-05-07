import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:classbunk_v1/screens/home_screen.dart';
import 'package:classbunk_v1/providers/app_provider.dart';
import 'package:classbunk_v1/services/database_service.dart';
import 'package:classbunk_v1/services/attendance_calculator.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  testWidgets('HomeScreen test', (WidgetTester tester) async {
    await Hive.initFlutter();
    final appProvider = AppProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appProvider,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
  });
}
