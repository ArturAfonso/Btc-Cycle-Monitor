import 'package:btc_cycle_monitor/features/home/presentation/widgets/bitcoin_preferences_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/home_loading.dart' as widgets;
import '../widgets/home_error.dart';
import '../widgets/bitcoin_chart.dart';
import '../widgets/bitcoin_stats.dart';
import '../widgets/bitcoin_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../indicators/presentation/pages/indicators_page.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(AppColors.backgroundColor),
        elevation: 0,
        title: Row(
          children: [
            
            Expanded(
              child: DragToMoveArea(
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/icons/bcm-logo-circular.png'), 
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BTC Cycle Monitor',
                          style: TextStyle(
                            color: Color(AppColors.textPrimary),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Acompanhamento em tempo real de Bitcoin',
                          style: TextStyle(
                            color: Color(AppColors.textSecondary),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const IndicatorsPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF334155),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.line_axis_rounded),
                      const SizedBox(width: 8),
                      Text(
                        'Indicadores',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(AppColors.textPrimary)),
            tooltip: 'Atualizar dados',
            onPressed: () {
              context.read<HomeCubit>().refreshData();
            },
          ),
          
          IconButton(
            icon: const Icon(Icons.minimize, color: Color(AppColors.textPrimary), size: 20),
            tooltip: 'Minimizar',
            onPressed: () async {
              await windowManager.minimize();
            },
          ),
          IconButton(
            icon: const Icon(Icons.crop_square, color: Color(AppColors.textPrimary), size: 18),
            tooltip: 'Maximizar/Restaurar',
            onPressed: () async {
              bool isMaximized = await windowManager.isMaximized();
              if (isMaximized) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(AppColors.textPrimary), size: 20),
            tooltip: 'Fechar',
            onPressed: () async {
              await windowManager.close();
            },
          ),
        ],
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeInitial || state is HomeLoading) {
            return const widgets.HomeLoading();
          } else if (state is HomeLoaded) {
            final bitcoinData = state.data.bitcoinData;
            if (bitcoinData == null) {
              return const Center(
                child: Text(
                  'Dados do Bitcoin não disponíveis',
                  style: TextStyle(color: Color(AppColors.textPrimary)),
                ),
              );
            }
            
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                 
                 
                  const SizedBox(height: 16),
                  
                  
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        Expanded(
                          flex: 2,
                          child: BitcoinChart(bitcoinData: bitcoinData),
                        ),
                        const SizedBox(width: 16),
                        
                        
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              
                              Expanded(
                                flex: 1,
                                child: BitcoinStats(bitcoinData: bitcoinData),
                              ),
                              const SizedBox(height: 16),
                              
                              
                              Expanded(
                                flex: 2,
                                child: AppPreferencesWithCubit(bitcoinData: bitcoinData),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else if (state is HomeError) {
            return HomeErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<HomeCubit>().loadHomeData();
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  



  
}


