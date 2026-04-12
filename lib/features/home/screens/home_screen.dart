import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../cubit/home_cubit.dart';
import '../../ai_assistant/screens/ai_assistant_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../expense/screens/expense_screen.dart';
import '../../expense/cubit/expense_cubit.dart';
import '../../shopping_schedule/screens/shopping_schedule_screen.dart';
import '../../meal_planning/screens/meal_plan_screen.dart';
import '../../meal_planning/cubit/meal_plan_cubit.dart';
import '../../meal_planning/models/meal_model.dart';
import '../../shopping_schedule/cubit/shopping_schedule_cubit.dart';
import '../../shopping_schedule/services/shopping_service.dart';
import '../../iot/screens/iot_dashboard_screen.dart';
import '../../iot/cubit/iot_cubit.dart';
import '../../health/screens/health_dashboard_screen.dart';
import '../../health/cubit/health_dashboard_cubit.dart';
import '../../wallet/screens/wallet_screen.dart';
import '../../auth/cubit/auth_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => HomeCubit()),
        BlocProvider(create: (context) => ExpenseCubit()..initialize()),
      ],
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  Future<bool> _onWillPop(BuildContext context, int selectedIndex) async {
    if (selectedIndex != 0) {
      // Return to home tab instead of exiting
      context.read<HomeCubit>().setTab(0);
      return false;
    }
    
    // On home tab, confirm exit
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Exit App',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Do you really want to exit the application?',
            style: GoogleFonts.manrope(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(color: Colors.grey[600], fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Exit',
                style: GoogleFonts.manrope(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
    
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await _onWillPop(context, state.selectedIndex);
            if (shouldPop) {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            body: IndexedStack(
              index: state.selectedIndex,
              children: [
                _buildHomeContent(context),
                const AiAssistantScreen(),
                const SettingsScreen(),
              ],
            ),
            bottomNavigationBar: _buildBottomNavigationBar(context, state),
          ),
        );
      },
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSummaryCarousel(context),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            _buildWidgetGrid(context),
          ],
        ),
      ),
    );
  }

  // 1. Header Section
  Widget _buildHeader() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        final photoUrl = user?.photoUrl;
        final displayName = user?.displayName ?? 'The Smiths';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: DecorationImage(
                        image: photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : const NetworkImage('https://i.pravatar.cc/150?img=12'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        )
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning,',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111418),
                    ),
                  ),
                  Text(
                    displayName,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                )
              ],
            ),
            child: Icon(Icons.notifications_outlined, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  },
);
  }

  // 2. Summary Carousel (Horizontal Scroll)
  Widget _buildSummaryCarousel(BuildContext context) {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, expenseState) {
        final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
        final balanceStr = formatter.format(expenseState.totalBalance);

        // Calculate budget progress (expense / income ratio)
        final budgetProgress = expenseState.totalIncome > 0
            ? (expenseState.totalIncome - expenseState.totalExpense) / expenseState.totalIncome
            : 0.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildSummaryCard(
                color: const Color(0xFF0D6CF2),
                title: 'Balance',
                value: balanceStr,
                icon: Icons.account_balance_wallet,
                footer: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: budgetProgress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(budgetProgress * 100).toStringAsFixed(0)}% left',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                color: const Color(0xFF34D399),
                title: 'Health Score',
                value: '85',
                valueSuffix: '/100',
                icon: Icons.favorite,
                textColor: const Color(0xFF064E3B),
                iconBg: Colors.black.withOpacity(0.05),
                footer: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 14, color: Color(0xFF064E3B)),
                      SizedBox(width: 4),
                      Text(
                        'Looking great!',
                        style: TextStyle(
                            color: Color(0xFF064E3B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required Color color,
    required String title,
    required String value,
    String? valueSuffix,
    required IconData icon,
    required Widget footer,
    Color textColor = Colors.white,
    Color? iconBg,
  }) {
    return Container(
      width: 240,
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: textColor.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(value,
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                          if (valueSuffix != null)
                            Text(valueSuffix,
                                style: TextStyle(
                                    color: textColor.withOpacity(0.7),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconBg ?? Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: textColor, size: 20),
                  ),
                ],
              ),
              footer,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                label: 'Expense',
                icon: Icons.add,
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExpenseScreen()),
                ),
              ),
              _buildActionButton(
                label: 'Shop',
                icon: Icons.shopping_cart,
                color: Colors.pink,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShoppingScheduleScreen()),
                ),
              ),
              _buildActionButton(
                label: 'Meal',
                icon: Icons.restaurant_menu,
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MealPlanScreen()),
                ),
              ),
              _buildActionButton(
                label: 'Health',
                icon: Icons.favorite,
                color: Colors.red,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HealthDashboardScreen()),
                ),
              ),
              _buildActionButton(
                label: 'Home',
                icon: Icons.devices,
                color: Colors.deepOrange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IotDashboardScreen()),
                ),
              ),
              _buildActionButton(
                label: 'Wallet',
                icon: Icons.account_balance_wallet,
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WalletScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildWidgetGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 220,
                  child: BlocBuilder<MealPlanCubit, MealPlanState>(
                    builder: (context, state) {
                      final mealTypes = [MealType.breakfast, MealType.lunch, MealType.dinner];
                      final typeLabels = ['BREAKFAST', 'LUNCH', 'DINNER'];
                      final times = ['8:00 AM', '12:30 PM', '7:00 PM'];
                      
                      return PageView.builder(
                        controller: PageController(initialPage: 3000), // Start with Breakfast
                        itemBuilder: (context, index) {
                          final typeIndex = index % 3;
                          final mealType = mealTypes[typeIndex];
                          final meal = state.getMealByType(mealType);
                          
                          final title = meal?.name ?? 'Not Planned';
                          
                          ImageProvider? imageProvider;
                          if (meal != null) {
                            if (meal.imageBytes != null && meal.imageBytes!.isNotEmpty) {
                              imageProvider = MemoryImage(meal.imageBytes!);
                            } else if (meal.imageUrl.isNotEmpty) {
                              imageProvider = NetworkImage(meal.imageUrl);
                            }
                          }
                          if (imageProvider == null) {
                            imageProvider = const NetworkImage('https://images.unsplash.com/photo-1495147466023-ac5c588e2e94?q=80&w=300&auto=format&fit=crop');
                          }
                          
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.restaurant, color: Colors.white, size: 16),
                                      const SizedBox(width: 4),
                                      Text(typeLabels[typeIndex], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(title,
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.1)),
                                  const SizedBox(height: 4),
                                  Text(times[typeIndex], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BlocBuilder<HealthDashboardCubit, HealthDashboardState>(
                  builder: (context, healthState) {
                    final steps = healthState.steps;
                    final goal = healthState.stepGoal;
                    final progress = healthState.stepProgress;

                    // Format steps: e.g. 6400 -> "6.4k", 850 -> "850"
                    String formattedSteps;
                    if (steps >= 1000) {
                      formattedSteps = '${(steps / 1000).toStringAsFixed(1)}k';
                    } else {
                      formattedSteps = steps.toString();
                    }

                    // Format goal: e.g. 10000 -> "10,000"
                    final formattedGoal = goal.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    );

                    return Container(
                      height: 220,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                      ),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.directions_walk, color: Colors.redAccent, size: 18),
                              SizedBox(width: 4),
                              Text('Steps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ],
                          ),
                          Expanded(
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 8,
                                      backgroundColor: const Color(0xFFF3F4F6),
                                      color: const Color(0xFF0D6CF2),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(formattedSteps, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          Text('Goal: $formattedGoal', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 160,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.pink[50], borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.list_alt, size: 16, color: Colors.pink)),
                              const SizedBox(width: 8),
                              const Text('To Buy', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              // Ensure it opens on Pending tab
                              context.read<ShoppingScheduleCubit>().setTab(0);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ShoppingScheduleScreen()),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              child: Text('See all', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: BlocBuilder<ShoppingScheduleCubit, ShoppingScheduleState>(
                          builder: (context, state) {
                            if (state.isLoading) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final pendingItems = state.pendingSchedules
                                .where((s) => s.paymentMode == PaymentMode.manual)
                                .take(3)
                                .toList();
                                
                            if (pendingItems.isEmpty) {
                              return Center(
                                child: Text('All caught up!', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                              );
                            }
                            
                            return Column(
                              children: pendingItems.map((schedule) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      final cubit = context.read<ShoppingScheduleCubit>();
                                      if (!state.isScheduleProcessing(schedule.id)) {
                                          cubit.markAsPaidManually(schedule.id);
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 16, 
                                          height: 16, 
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey[300]!), 
                                            borderRadius: BorderRadius.circular(4),
                                            color: Colors.white,
                                          ),
                                          child: state.isScheduleProcessing(schedule.id)
                                              ? const Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            schedule.title, 
                                            style: TextStyle(fontSize: 13, color: Colors.grey[700]), 
                                            overflow: TextOverflow.ellipsis
                                          )
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 160,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.bolt, size: 16, color: Colors.orange)),
                          const SizedBox(width: 8),
                          const Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<IotCubit, IotState>(
                        builder: (context, iotState) {
                          return Row(
                            children: [
                              Expanded(child: _buildHomeStatusItem(Icons.water_drop, Colors.blue, '${iotState.humidity.toStringAsFixed(1)}%')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildHomeStatusItem(Icons.thermostat, Colors.orange, '${iotState.temperature.toStringAsFixed(1)}°C')),
                            ],
                          );
                        },
                      ),
                      const Spacer(),
                      Text('All systems normal', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 16, height: 16, decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700]), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildHomeStatusItem(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, HomeState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: BottomNavigationBar(
        currentIndex: state.selectedIndex,
        onTap: (index) => context.read<HomeCubit>().setTab(index),
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0D6CF2),
        unselectedItemColor: Colors.grey[400],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Ask AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
