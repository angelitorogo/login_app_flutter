
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:login_app/presentation/providers/auth/auth_provider.dart';
import 'package:login_app/presentation/screens/auth/login_screen.dart';
import 'package:login_app/presentation/screens/core/logado/logado_screen.dart';
import 'package:login_app/presentation/screens/core/no_logado/no_logado_screen.dart';
import 'package:login_app/presentation/screens/core/profile/profile_screen.dart';
import 'package:login_app/presentation/screens/core/prueba/prueba_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/core', 
  routes: [
    // State-Preserving
    /*
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => HomeScreen(childView: navigationShell),
      branches: [
        
        StatefulShellBranch(
          routes: [

            GoRoute(
              path: '/',
              builder: (context, state) => const HomeView(),
              routes: [
                GoRoute(
                    path: 'movie/:id',
                    name: MovieScreen.name,
                    builder: (context, state) {
                      final movieId = state.pathParameters['id'] ?? 'no-id';
                      return MovieScreen(movieId: movieId);
                    },
                  ),
              ]
            ),

        ]),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/categories',
              builder: (context, state) {
                return const CategoriesView();
              },
            )
        ]),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              builder: (context, state) {
                return const FavouriteView();
              },
            )
        ]),
      ]),*/

    GoRoute(
      path: '/login',
      name: LoginScreen.name,
      builder: (context, state) => const LoginScreen(),
    ),  

    GoRoute(
      path: '/core',
      name: PruebaScreen.name,
      builder: (context, state) => const PruebaScreen(),
    ), 

    GoRoute(
      path: '/protegida',
      name: LogadoScreen.name,
      builder: (context, state) {
        // ✅ Obtenemos el estado de autenticación usando ProviderScope.of()
        final authState = ProviderScope.containerOf(context).read(authProvider);

        // 🔒 Si el usuario NO está autenticado, lo enviamos a /login
        if (!authState.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            GoRouter.of(context).go('/login');
          });
          return const SizedBox(); // Devolvemos un widget vacío mientras redirige
        }

        return const LogadoScreen(); // ✅ Si está autenticado, accede a la ruta
      },
    ),

    GoRoute(
      path: '/profile',
      name: ProfileScreen.name,
      builder: (context, state) {
        // ✅ Obtenemos el estado de autenticación usando ProviderScope.of()
        final authState = ProviderScope.containerOf(context).read(authProvider);

        // 🔒 Si el usuario NO está autenticado, lo enviamos a /login
        if (!authState.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            GoRouter.of(context).go('/login');
          });
          return const SizedBox(); // Devolvemos un widget vacío mientras redirige
        }

        return const ProfileScreen(); // ✅ Si está autenticado, accede a la ruta
      },
    ),

    GoRoute(
      path: '/no-protegida',
      name: NoLogadoScreen.name,
      builder: (context, state) => const NoLogadoScreen(),
    ),    


]);


