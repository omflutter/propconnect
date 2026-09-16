import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:propconnect/features/splash/presentation/screens/splash_screen.dart';
import 'package:propconnect/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:propconnect/features/auth/presentation/screens/login_screen.dart';
import 'package:propconnect/features/auth/presentation/screens/register_screen.dart';
import 'package:propconnect/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:propconnect/features/dashboard/presentation/screens/main_dashboard_screen.dart';
import 'package:propconnect/features/home/presentation/screens/home_screen.dart';
import 'package:propconnect/features/properties/presentation/screens/properties_screen.dart';
import 'package:propconnect/features/search/presentation/screens/search_screen.dart';
import 'package:propconnect/features/deals/presentation/screens/deals_screen.dart';
import 'package:propconnect/features/more/presentation/screens/more_screen.dart';
import 'package:propconnect/features/chat/presentation/screens/chat_screen.dart';
import 'package:propconnect/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:propconnect/features/finance/presentation/screens/commissions_screen.dart';
import 'package:propconnect/features/crm/presentation/screens/leads_screen.dart';
import 'package:propconnect/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:propconnect/features/agency/presentation/screens/agency_management_screen.dart';
import 'package:propconnect/features/agency/presentation/screens/broker_details_screen.dart';
import 'package:propconnect/features/agency/presentation/screens/create_agency_screen.dart';
import 'package:propconnect/features/properties/presentation/screens/property_details_screen.dart';
import 'package:propconnect/features/collaborations/presentation/screens/collaborations_screen.dart';
import 'package:propconnect/features/collaborations/presentation/screens/collaboration_details_screen.dart';
import 'package:propconnect/features/deals/presentation/screens/deal_details_screen.dart';
import 'package:propconnect/features/deals/presentation/screens/add_deal_screen.dart';
import 'package:propconnect/features/settings/presentation/screens/settings_screen.dart';
import 'package:propconnect/features/support/presentation/screens/help_support_screen.dart';
import 'package:propconnect/features/chat/presentation/screens/chat_details_screen.dart';
import 'package:propconnect/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:propconnect/features/profile/presentation/screens/my_profile_screen.dart';
import 'package:propconnect/features/properties/presentation/screens/add_edit_property_screen.dart';

// Keys for StatefulShellRoute branches
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellNavigatorPropertiesKey = GlobalKey<NavigatorState>(debugLabel: 'shellProperties');
final _shellNavigatorSearchKey = GlobalKey<NavigatorState>(debugLabel: 'shellSearch');
final _shellNavigatorDealsKey = GlobalKey<NavigatorState>(debugLabel: 'shellDeals');
final _shellNavigatorCollaborationsKey = GlobalKey<NavigatorState>(debugLabel: 'shellCollaborations');

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // Dashboard routes
  static const String home = '/home';
  static const String properties = '/properties';
  static const String search = '/search';
  static const String deals = '/deals';
  static const String more = '/more';
  
  // Auxiliary routes
  static const String chat = '/chat';
  static const String notifications = '/notifications';
  static const String commissions = '/commissions';
  static const String leads = '/leads';
  static const String analytics = '/analytics';
  static const String agencyManagement = '/agency-management';
  static const String createAgency = '/create-agency';
  static const String subscription = '/subscription';
  static const String profile = '/profile';
  static const String brokerDetails = '/broker-details/:id';
  static const String propertyDetails = '/property-details/:id';
  static const String collaborations = '/collaborations';
  static const String collaborationDetails = '/collaboration-details/:id';
  static const String dealDetails = '/deal-details/:id';
  static const String addDeal = '/add-deal';
  static const String chatDetails = '/chat/:id';
  static const String addEditProperty = '/add-edit-property/:id';
  static const String settings = '/settings';
  static const String support = '/support';

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: chat,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: commissions,
        builder: (context, state) => const CommissionsScreen(),
      ),
      GoRoute(
        path: leads,
        builder: (context, state) => const LeadsScreen(),
      ),
      GoRoute(
        path: analytics,
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: agencyManagement,
        builder: (context, state) => const AgencyManagementScreen(),
      ),
      GoRoute(
        path: createAgency,
        builder: (context, state) => const CreateAgencyScreen(),
      ),
      GoRoute(
        path: subscription,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: profile,
        builder: (context, state) => const MyProfileScreen(),
      ),
      GoRoute(
        path: brokerDetails,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final isInternalStr = state.uri.queryParameters['isInternal'];
          final isInternal = isInternalStr?.toLowerCase() == 'true';
          return BrokerDetailsScreen(brokerId: id, isInternal: isInternal);
        },
      ),
      GoRoute(
        path: propertyDetails,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PropertyDetailsScreen(propertyId: id);
        },
      ),
      GoRoute(
        path: chatDetails,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ChatDetailsScreen(
            chatId: id,
            partnerName: extra?['partnerName'] as String? ?? state.uri.queryParameters['partnerName'],
            partnerId: extra?['partnerId'] as String? ?? state.uri.queryParameters['partnerId'],
            agencyName: extra?['agencyName'] as String? ?? state.uri.queryParameters['agencyName'],
          );
        },
      ),
      GoRoute(
        path: addEditProperty,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEditPropertyScreen(propertyId: id);
        },
      ),
      GoRoute(
        path: more,
        builder: (context, state) => const MoreScreen(),
      ),
      GoRoute(
        path: collaborationDetails,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CollaborationDetailsScreen(dealId: id);
        },
      ),
      GoRoute(
        path: dealDetails,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DealDetailsScreen(dealId: id);
        },
      ),
      GoRoute(
        path: addDeal,
        builder: (context, state) => const AddDealScreen(),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: support,
        builder: (context, state) => const HelpSupportScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainDashboardScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: home,
                pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorPropertiesKey,
            routes: [
              GoRoute(
                path: properties,
                pageBuilder: (context, state) => const NoTransitionPage(child: PropertiesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSearchKey,
            routes: [
              GoRoute(
                path: search,
                pageBuilder: (context, state) => const NoTransitionPage(child: SearchScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDealsKey,
            routes: [
              GoRoute(
                path: deals,
                pageBuilder: (context, state) => const NoTransitionPage(child: DealsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCollaborationsKey,
            routes: [
              GoRoute(
                path: collaborations,
                pageBuilder: (context, state) => const NoTransitionPage(child: CollaborationsScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri.path}'),
      ),
    ),
  );
}
