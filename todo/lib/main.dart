import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:todo/src/bloc/theme_bloc.dart';
import 'package:todo/src/bloc/todo_bloc.dart';
import 'package:todo/src/bloc/todo_event.dart';
import 'package:todo/src/core/db/db_helpher.dart';
import 'package:todo/src/core/theme/app_theme.dart';
import 'package:todo/src/view/Splash.dart';
import 'package:todo/src/view/todo_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeBloc()),
        BlocProvider(create: (_) => TodoBloc(DBHelper())..add(LoadTodos())),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ScreenUtilInit(
            designSize: _getDesignSize(constraints.maxWidth),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, _) {
              return BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, themeState) {
                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    title: 'TaskMaster',
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: themeState.themeMode,
                    home: const SplashScreen(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

Size _getDesignSize(double width) {
  if (width < 600) return const Size(360, 690);
  if (width < 1200) return const Size(834, 1194);
  return const Size(1440, 1024);
}