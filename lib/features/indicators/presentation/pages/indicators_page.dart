import 'package:btc_cycle_monitor/core/utils/utility.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/preferences/preferences_cubit.dart';
import '../../../../core/preferences/preferences_state.dart';
import '../../../../core/services/notification_service.dart';
import '../../../home/data/api/coingecko_api.dart';
import '../../data/api/fear_greed_api.dart';
import '../cubit/fear_greed_cubit.dart';
import '../cubit/pi_cycle_top_cubit.dart';
import '../cubit/pi_cycle_top_state.dart';
import '../cubit/bitcoin_dominance_cubit.dart';
import '../cubit/bitcoin_dominance_state.dart';
import '../widgets/fear_greed_gauge.dart';
import '../widgets/pi_cycle_top_widget.dart';
import '../widgets/bitcoin_dominance_widget.dart';

/// Página de indicadores técnicos do Bitcoin
class IndicatorsPage extends StatelessWidget {
  const IndicatorsPage({super.key});

  // artafonso.com  godday
  //   arturafonso.plataforma

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => FearGreedCubit(api: FearGreedApi())..loadFearGreedIndex()),
        BlocProvider(
          create: (context) {
            final cubit = PiCycleTopCubit(CoinGeckoApi());
            // Carrega com a moeda atual
            final prefsState = context.read<PreferencesCubit>().state;
            if (prefsState is PreferencesLoaded) {
              cubit.updateCurrency(prefsState.selectedCurrency);
            } else {
              cubit.loadPiCycleTop();
            }
            return cubit;
          },
        ),
        BlocProvider(create: (context) => BitcoinDominanceCubit(CoinGeckoApi())..loadBitcoinDominance()),
      ],
      child: BlocListener<PreferencesCubit, PreferencesState>(
        listener: (context, prefsState) {
          // Quando a moeda mudar, atualiza o Pi Cycle Top
          if (prefsState is PreferencesLoaded) {
            context.read<PiCycleTopCubit>().updateCurrency(prefsState.selectedCurrency);
          }
        },
        child: _IndicatorsPageContent(),
      ),
    );
  }
}

class _IndicatorsPageContent extends StatelessWidget {
  const _IndicatorsPageContent();

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
            // Área arrastável (logo + texto)
            Expanded(
              child: DragToMoveArea(
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(image: AssetImage('assets/icons/bcm-logo-circular.png'), fit: BoxFit.scaleDown),
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
                          style: TextStyle(color: Color(AppColors.textSecondary), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Botão Voltar (não arrastável)
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Color(0xFF334155), borderRadius: BorderRadius.circular(16)),
                child: Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_ios_new, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'Voltar',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
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
              context.read<FearGreedCubit>().refresh();
              context.read<PiCycleTopCubit>().reload();
              context.read<BitcoinDominanceCubit>().refresh();
            },
          ),
          // Botões de controle de janela customizados
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
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com título da seção
            Text(
              'Indicadores Técnicos',
              style: TextStyle(color: Color(AppColors.textPrimary), fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),

            // Conteúdo principal com scroll
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}),
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Coluna esquerda - Indicadores de Momentum
                      Expanded(
                        child: Column(
                          children: [
                            // Fear & Greed Index com dados reais
                            BlocBuilder<FearGreedCubit, FearGreedState>(
                              builder: (context, state) {
                                if (state is FearGreedLoading) {
                                  return _CustomIndicatorCard(
                                    title: 'Índice de Medo e Ganância',
                                    status: "Carregando...",
                                    value: '--',
                                    description: 'Aguardando dados da API...',
                                    color: Color(0xFFFFB800),
                                    icon: Icons.trending_flat,
                                    isLoading: true,
                                    cardFunction: () {},
                                  );
                                } else if (state is FearGreedLoaded) {
                                  return _CustomIndicatorCard(
                                    cardFunction: () {
                                      _showFearGreedInfo(context, state.data.value, state.data.classificationPtBr);
                                    },
                                    title: 'Índice de Medo e Ganância',
                                    status: state.data.classificationPtBr, // Traduzido para PT-BR
                                    value: state.data.value.toString(),
                                    description:
                                        'Funciona como um "termômetro" da emoção do mercado: 0 significa Pânico (Medo Extremo) e 100 significa Euforia (Ganância Extrema).', //'Sua escala vai de 0 a 100, e leituras acima de 90 sinalizam um mercado possivelmente superaquecido.',
                                    color: _getColorFromHex(state.data.colorHex),
                                    icon: Icons.trending_flat,
                                    fearGreedValue: state.data.value,
                                    fearGreedClassification: state.data.classificationPtBr, // Traduzido para PT-BR
                                  );
                                } else if (state is FearGreedError) {
                                  return _CustomIndicatorCard(
                                    cardFunction: () {},
                                    title: 'Índice de Medo e Ganância',
                                    status: "Erro",
                                    value: '--',
                                    description: state.message,
                                    color: Color(0xFFEF4444),
                                    icon: Icons.error_outline,
                                  );
                                }
                                return SizedBox.shrink();
                              },
                            ),
                            SizedBox(height: 16)/* ,
_CustomIndicatorCard(
                                    title: 'teste notificaçao',
                                    status: "Carregando...",
                                    value: '--',
                                    description: 'testando notificaçao do windows...',
                                    color: Color(0xFFFFB800),
                                    icon: Icons.trending_flat,
                                    isLoading: false,
                                    cardFunction: () {},

                                  ) */
                            /*  SizedBox(height: 16),
                              _CustomIndicatorCard(
                                  cardFunction: () { },
                                title: 'lorem ipsubn',
                                value: 'lorem ipsubn',
                                status: 'lorem ipsubn',
                                description: 'Oversold',
                                color: Color(0xFF22C55E),
                                icon: Icons.trending_up,
                              ),  */
                          ],
                        ),
                      ),

                      SizedBox(width: 20),

                      // Coluna direita - Indicadores de Trend
                      Expanded(
                        child: Column(
                          children: [
                            // Pi Cycle Top com dados reais
                            BlocBuilder<PiCycleTopCubit, PiCycleTopState>(
                              builder: (context, state) {
                                if (state is PiCycleTopLoading) {
                                  return _CustomIndicatorCard(
                                    cardFunction: () {},
                                    title: 'Pi Cycle Top',
                                    status: "Carregando...",
                                    value: '--',
                                    description: 'Aguardando dados da API...',
                                    color: Color(0xFFFFB800),
                                    icon: Icons.trending_flat,
                                    isLoading: true,
                                  );
                                } else if (state is PiCycleTopLoaded) {
                                  return BlocBuilder<PreferencesCubit, PreferencesState>(
                                    builder: (context, preferencesState) {
                                      String selectedCurrency = 'USD'; // Default

                                      if (preferencesState is PreferencesLoaded) {
                                        selectedCurrency = preferencesState.selectedCurrency;
                                      }

                                      return _CustomIndicatorCard(
                                        cardFunction: () {
                                          _showPiCycleTopInfo(context, state);
                                        },
                                        title: 'Pi Cycle Top',
                                        status: state.isTop
                                            ? "TOPO"
                                            : state.isApproaching
                                            ? "APROXIMANDO"
                                            : "NORMAL",
                                        value: state.sma111 != null
                                            ? Utility().priceToCurrency(state.sma111!, fiat: selectedCurrency)
                                            : '--',
                                        description: 'Indicador que detecta topos de mercado com base em médias móveis',
                                        color: state.isTop
                                            ? Color(0xFFEF4444)
                                            : state.isApproaching
                                            ? Color(0xFFFFB800)
                                            : Color(0xFF22C55E),
                                        icon: state.isTop
                                            ? Icons.warning_rounded
                                            : state.isApproaching
                                            ? Icons.trending_up_rounded
                                            : Icons.check_circle_rounded,
                                        piCycleData: state,
                                      );
                                    },
                                  );
                                } else if (state is PiCycleTopError) {
                                  return _CustomIndicatorCard(
                                    cardFunction: () {},
                                    title: 'Pi Cycle Top',
                                    status: "Erro",
                                    value: '--',
                                    description: state.message,
                                    color: Color(0xFFEF4444),
                                    icon: Icons.error_outline,
                                  );
                                }
                                return SizedBox.shrink();
                              },
                            ),
                            SizedBox(height: 16),

                            // Card de Dominância do Bitcoin
                            BlocBuilder<BitcoinDominanceCubit, BitcoinDominanceState>(
                              builder: (context, state) {
                                if (state is BitcoinDominanceLoading) {
                                  return _CustomIndicatorCard(
                                    cardFunction: () {},
                                    title: 'Dominância BTC',
                                    status: "Carregando...",
                                    value: '--',
                                    description: 'Carregando dados de dominância...',
                                    color: Color(0xFF94A3B8),
                                    icon: Icons.public_rounded,
                                    isLoading: true,
                                  );
                                } else if (state is BitcoinDominanceLoaded) {
                                  return _CustomIndicatorCard(
                                    cardFunction: () {
                                      _showBitcoinDominanceInfo(context, state.dominance, state.status, state.message);
                                    },
                                    title: 'Dominância BTC',
                                    status: state.message.split(' - ').first, // Pega só a primeira parte
                                    value: '${state.dominance.toStringAsFixed(1)}%', // Dados reais da API
                                    description: 'Porcentagem do Bitcoin no mercado total de criptomoedas',
                                    color: _getBitcoinDominanceColor(state.status), // Dados reais da API
                                    icon: _getBitcoinDominanceIcon(state.status), // Dados reais da API
                                    bitcoinDominanceData: state,

                                    // 🧪 MOCKS PARA TESTE - Descomente para testar cenários específicos

                                    // 🛡️ MEDO EXTREMO
                                    // value: '75.0%',
                                    // color: _getBitcoinDominanceColor('extreme_fear'),
                                    // icon: _getBitcoinDominanceIcon('extreme_fear'),

                                    // 📈 MEDO
                                    // value: '60.0%',
                                    // color: _getBitcoinDominanceColor('fear'),
                                    // icon: _getBitcoinDominanceIcon('fear'),

                                    // ⚖️ NEUTRO
                                    // value: '50.0%',
                                    // color: _getBitcoinDominanceColor('neutral'),
                                    // icon: _getBitcoinDominanceIcon('neutral'),

                                    // 🚀 GANÂNCIA
                                    // value: '40.0%',
                                    // color: _getBitcoinDominanceColor('greed'),
                                    // icon: _getBitcoinDominanceIcon('greed'),

                                    // 🌙 GANÂNCIA EXTREMA
                                    // value: '30.0%',
                                    // color: _getBitcoinDominanceColor('extreme_greed'),
                                    // icon: _getBitcoinDominanceIcon('extreme_greed'),
                                  );
                                } else if (state is BitcoinDominanceError) {
                                  return _CustomIndicatorCard(
                                    cardFunction: () {},
                                    title: 'Dominância BTC',
                                    status: "Erro",
                                    value: '--',
                                    description: state.message,
                                    color: Color(0xFFEF4444),
                                    icon: Icons.error_outline,
                                  );
                                }
                                return SizedBox.shrink();
                              },
                            ),

                            /* SizedBox(height: 16),
                              _CustomIndicatorCard(
                                  cardFunction: () { },
                                title: 'lorem ipsubn',
                                value: 'lorem ipsubn',
                                status: 'lorem ipsubn',
                                description: 'Lower Band',
                                color: Color(0xFFFFB800),
                                icon: Icons.analytics,
                              ), */
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            //_SummaryCard()
          ],
        ),
      ),
    );
  }

  /// Converte hex string para Color
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  /// Mostra dialog explicativo sobre o Pi Cycle Top
  void _showPiCycleTopInfo(BuildContext context, PiCycleTopLoaded state) {
    // Calcula a porcentagem atual
    final percentage = state.sma111 != null && state.sma350x2 != null ? (state.sma111! / state.sma350x2!) * 100 : 0.0;

    // Define zona e interpretação
    String zona;
    String emoji;
    String interpretacao;
    String acao;
    Color corZona;

    if (percentage <= 30) {
      zona = "FRIO (Fundo do Poço)";
      emoji = "🥶";
      interpretacao =
          "O mercado está 'frio'. O Bitcoin está em bear market ou no fundo de um ciclo. O 'hype' desapareceu completamente.";
      acao = "Zona de Oportunidade - Historicamente o melhor momento para comprar";
      corZona = Colors.blue.shade400;
    } else if (percentage <= 70) {
      zona = "AQUECENDO (Meio do Caminho)";
      emoji = "😊";
      interpretacao =
          "O mercado está 'aquecendo'. Estamos no meio de um bull market. O preço está subindo de forma saudável, mas ainda não atingiu níveis de euforia perigosa.";
      acao = "Manter - Estamos em um ciclo de alta saudável";
      corZona = Colors.green.shade400;
    } else if (percentage < 100) {
      zona = "SUPERAQUECIDO (Aproximando do Pico)";
      emoji = "🔥";
      interpretacao =
          "O mercado está entrando em euforia. O 'hype' de curto prazo está se aproximando perigosamente da linha de longo prazo.";
      acao = "Atenção - Possível pico se aproximando";
      corZona = Colors.orange.shade400;
    } else {
      zona = "PICO ATINGIDO (Perigo Máximo)";
      emoji = "🚨";
      interpretacao =
          "ALERTA MÁXIMO! O indicador atingiu 100%. Historicamente, quando isso acontece, o Bitcoin atinge o pico absoluto do ciclo.";
      acao = "Zona de Perigo - Considere realizar lucros";
      corZona = Colors.red.shade400;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.blue.shade400, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pi Cycle Top Explicado',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status atual
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: corZona.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: corZona.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${percentage.toStringAsFixed(0)}% - $zona',
                              style: TextStyle(color: corZona, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(interpretacao, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(
                        '💡 $acao',
                        style: TextStyle(color: corZona, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Explicação geral
                const Text(
                  'Como Funciona?',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pense neste indicador como um "Medidor de Hype" do Bitcoin. Ele compara a velocidade recente do preço com sua tendência de longo prazo.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),

                const SizedBox(height: 12),

                // Dica sobre psicologia do mercado
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.amber.shade400, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Psicologia do Mercado',
                            style: TextStyle(color: Colors.amber.shade400, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '🔥 Mercado Superaquecido (90-100%): Geralmente quando investidores iniciantes entram por emoção e FOMO, enquanto investidores experientes realizam lucros.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '🥶 Mercado Frio (0-30%): Quando há pouco "hype" e investidores experientes costumam acumular posições.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '⚠️ Esta não é uma recomendação de investimento, apenas observação de padrões históricos.',
                        style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tabela de zonas
                const Text(
                  'Zonas de Interpretação:',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                _buildZonaInfo('🥶', '0% - 30%', 'Frio', 'Zona de Oportunidade', Colors.blue.shade400),
                _buildZonaInfo('😊', '40% - 70%', 'Aquecendo', 'Manter Posição', Colors.green.shade400),
                _buildZonaInfo('🔥', '90% - 100%', 'Superaquecido', 'Zona de Perigo', Colors.red.shade400),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Entendi',
                style: TextStyle(color: Colors.blue.shade400, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildZonaInfo(String emoji, String range, String nome, String acao, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            range,
            style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$nome - $acao', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// Mostra dialog explicativo sobre o Índice de Medo e Ganância
  void _showFearGreedInfo(BuildContext context, int fearGreedValue, String fearGreedClassification) {
    // Define zona e interpretação baseada no valor
    String zona;
    String emoji;
    String interpretacao;
    String acao;
    Color corZona;

    if (fearGreedValue <= 25) {
      zona = "MEDO EXTREMO (0-25)";
      emoji = "😱";
      interpretacao =
          "Pânico generalizado no mercado. Investidores vendendo de forma irracional, com medo de perdas maiores.";
      acao = "Oportunidade Histórica - Mercado pode estar no fundo (capitulação)";
      corZona = Colors.red.shade400;
    } else if (fearGreedValue <= 45) {
      zona = "MEDO (25-45)";
      emoji = "😰";
      interpretacao =
          "Sentimento geral de pessimismo, ansiedade e incerteza. Notícias negativas e baixo interesse do público.";
      acao = "Zona de Acumulação - Considere compras graduais";
      corZona = Colors.orange.shade400;
    } else if (fearGreedValue <= 55) {
      zona = "NEUTRO (45-55)";
      emoji = "😐";
      interpretacao = "Mercado em equilíbrio, sem uma emoção dominante clara. Momento de observação e análise.";
      acao = "Manter Posição - Aguarde sinais mais claros";
      corZona = Colors.yellow.shade600;
    } else if (fearGreedValue <= 75) {
      zona = "GANÂNCIA (55-75)";
      emoji = "😊";
      interpretacao =
          "Otimismo alto. FOMO começando a aparecer, mais pessoas entrando no mercado esperando lucros fáceis.";
      acao = "Atenção - Considere realizar lucros parciais";
      corZona = Colors.lightGreen.shade400;
    } else {
      zona = "GANÂNCIA EXTREMA (75-100)";
      emoji = "🤑";
      interpretacao = "Euforia máxima! Mercado superaquecido, todos otimistas, cautela deixada de lado.";
      acao = "Zona de Perigo - Topo de mercado pode estar próximo";
      corZona = Colors.green.shade400;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.psychology_outlined, color: Colors.amber.shade400, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Índice de Medo e Ganância',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status atual
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: corZona.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: corZona.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              zona,
                              style: TextStyle(color: corZona, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(interpretacao, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(
                        '💡 $acao',
                        style: TextStyle(color: corZona, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Explicação geral
                const Text(
                  '💡 O que é o Índice de Medo e Ganância?',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Este índice mede o sentimento emocional dos investidores, onde o Medo Extremo (perto de 0) pode indicar uma oportunidade de compra, e a Ganância Extrema (perto de 100) pode sinalizar uma correção.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Ele não mede o valor real do Bitcoin, mas sim a psicologia da multidão. A ideia é que o mercado é movido por duas emoções principais: medo e ganância.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),

                const SizedBox(height: 12),

                // Estratégia contrária
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.blue.shade400, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Estratégia Contrária',
                            style: TextStyle(color: Colors.blue.shade400, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '📈 Medo Extremo: Pânico causa vendas excessivas, preços ficam "baratos" demais.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '📉 Ganância Extrema: Euforia e FOMO levam preços a ficarem "caros" demais.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '💭 "Seja medroso quando os outros são gananciosos e ganancioso quando os outros estão com medo." - Warren Buffett',
                        style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Como é calculado
                const Text(
                  '⚙️ Como é Calculado?',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                _buildCalculoInfo('📊', 'Volatilidade (25%)', 'Compara volatilidade atual com médias de 30-90 dias'),
                _buildCalculoInfo('📈', 'Volume e Momento (25%)', 'Analisa volume de negociação vs médias recentes'),
                _buildCalculoInfo('📱', 'Mídias Sociais (15%)', 'Sentimento em posts e hashtags no Twitter'),
                _buildCalculoInfo('₿', 'Dominância Bitcoin (10%)', 'Participação do BTC no mercado total de crypto'),
                _buildCalculoInfo(
                  '🔍',
                  'Tendências Google (10%)',
                  'Volume de buscas por termos relacionados ao Bitcoin',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Entendi',
                style: TextStyle(color: Colors.amber.shade400, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalculoInfo(String emoji, String titulo, String descricao) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(descricao, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mostra dialog explicativo sobre a Dominância do Bitcoin
  void _showBitcoinDominanceInfo(BuildContext context, double dominance, String status, String message) {
    // Define zona e interpretação baseada na dominância
    String zona;
    String emoji;
    String interpretacao;
    String acao;
    Color corZona;

    if (dominance >= 65) {
      zona = "MEDO EXTREMO (Fuga para BTC)";
      emoji = "🛡️";
      interpretacao =
          "O mercado está em pânico. Investidores estão fugindo das altcoins arriscadas e se protegendo no Bitcoin. Esta é uma fase de 'flight to safety'.";
      acao = "Início de Ciclo - Oportunidade de acumulação";
      corZona = const Color(0xFF3B82F6);
    } else if (dominance >= 55) {
      zona = "MEDO (Preferência pelo BTC)";
      emoji = "📈";
      interpretacao =
          "O mercado ainda prefere a 'segurança' do Bitcoin. As altcoins estão sendo negligenciadas. Bear market ou início de bull market.";
      acao = "Bear Market - Cautela e paciência";
      corZona = const Color(0xFF06B6D4);
    } else if (dominance >= 45) {
      zona = "NEUTRO (Equilíbrio)";
      emoji = "⚖️";
      interpretacao =
          "O mercado está equilibrado entre Bitcoin e altcoins. Não há uma tendência emocional dominante clara.";
      acao = "Meio de Ciclo - Observar tendências";
      corZona = const Color(0xFFFFB800);
    } else if (dominance >= 35) {
      zona = "GANÂNCIA (Altcoins em Alta)";
      emoji = "🚀";
      interpretacao =
          "O dinheiro está fluindo do Bitcoin para as altcoins. Investidores estão buscando maiores retornos em projetos alternativos.";
      acao = "Bull Market - Atenção aos riscos";
      corZona = const Color(0xFFEAB308);
    } else {
      zona = "GANÂNCIA EXTREMA (Altseason)";
      emoji = "🌙";
      interpretacao =
          "EUFORIA MÁXIMA! O dinheiro está saindo massivamente do Bitcoin para altcoins. Esta é a famosa 'Altseason' - sinal de possível topo de ciclo.";
      acao = "Fim de Ciclo - Zona de Perigo";
      corZona = const Color(0xFFEF4444);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.public_rounded, color: Colors.orange.shade400, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Dominância do Bitcoin Explicada',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status atual
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: corZona.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: corZona.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              zona,
                              style: TextStyle(color: corZona, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dominância atual: ${dominance.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(interpretacao, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(
                        '💡 $acao',
                        style: TextStyle(color: corZona, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Explicação geral
                const Text(
                  'O que é Dominância do Bitcoin?',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'É a porcentagem do mercado total de criptomoedas que está alocada no Bitcoin. Este é um dos melhores indicadores de "fluxo de dinheiro" e apetite a risco no mercado cripto.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),

                const SizedBox(height: 12),

                // Dica sobre psicologia do mercado
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology_rounded, color: Colors.amber.shade400, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Psicologia do Fluxo de Capital',
                            style: TextStyle(color: Colors.amber.shade400, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '🛡️ Dominância Alta (65%+): "Flight to Safety" - Investidores fogem de altcoins arriscadas para a "segurança" do Bitcoin durante bear markets.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '🚀 Dominância Baixa (35%-): "Altseason" - Euforia máxima! Dinheiro sai do Bitcoin para altcoins buscando retornos 100x. Sinal clássico de topo de ciclo.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '⚡ Regra Histórica: Quando dominância despenca abaixo de 40%, o mercado geralmente está próximo de um topo de ciclo.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tabela de zonas
                const Text(
                  'Zonas de Interpretação:',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                _buildDominanceZonaInfo('🛡️', '65%+', 'Medo Extremo', 'Início de Ciclo', const Color(0xFF3B82F6)),
                _buildDominanceZonaInfo('📈', '55-65%', 'Medo', 'Bear Market', const Color(0xFF06B6D4)),
                _buildDominanceZonaInfo('⚖️', '45-55%', 'Neutro', 'Meio de Ciclo', const Color(0xFFFFB800)),
                _buildDominanceZonaInfo('🚀', '35-45%', 'Ganância', 'Bull Market', const Color(0xFFEAB308)),
                _buildDominanceZonaInfo('🌙', 'Abaixo 35%', 'Altseason', 'Fim de Ciclo', const Color(0xFFEF4444)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Entendi',
                style: TextStyle(color: Colors.orange.shade400, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Retorna a cor baseada no status da dominância
  Color _getBitcoinDominanceColor(String status) {
    switch (status) {
      case 'extreme_fear':
        return const Color(0xFF3B82F6); // Azul
      case 'fear':
        return const Color(0xFF06B6D4); // Ciano
      case 'neutral':
        return const Color(0xFFFFB800); // Amarelo
      case 'greed':
        return const Color(0xFFEAB308); // Laranja
      case 'extreme_greed':
        return const Color(0xFFEF4444); // Vermelho
      default:
        return const Color(0xFF6B7280); // Cinza
    }
  }

  /// Retorna o ícone baseado no status da dominância
  IconData _getBitcoinDominanceIcon(String status) {
    switch (status) {
      case 'extreme_fear':
        return Icons.shield; // Proteção/segurança
      case 'fear':
        return Icons.trending_up; // Subindo para BTC
      case 'neutral':
        return Icons.balance; // Equilíbrio
      case 'greed':
        return Icons.trending_down; // Descendo do BTC
      case 'extreme_greed':
        return Icons.rocket_launch; // Altseason
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildDominanceZonaInfo(String emoji, String range, String nome, String acao, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            range,
            style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$nome - $acao', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _CustomIndicatorCard extends StatelessWidget {
  final String title;
  final String value;
  final String status;
  final String description;
  final Color color;
  final IconData icon;
  final bool isLoading;
  final int? fearGreedValue; // Valor numérico para o gauge (0-100)
  final String? fearGreedClassification; // Classificação textual
  final PiCycleTopLoaded? piCycleData; // Dados do Pi Cycle Top
  final BitcoinDominanceLoaded? bitcoinDominanceData; // Dados da dominância do Bitcoin
  final void Function() cardFunction;

  const _CustomIndicatorCard({
    required this.title,
    required this.value,
    required this.status,
    required this.description,
    required this.color,
    required this.icon,
    this.isLoading = false,
    this.fearGreedValue,
    this.fearGreedClassification,
    this.piCycleData,
    this.bitcoinDominanceData,
    required this.cardFunction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 430, // Altura fixa para todos os cards
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(AppColors.cardColor), borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: cardFunction,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70, width: 2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(Icons.question_mark_sharp, size: 16, color: Colors.white70),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: isLoading ? Color(0xFF94A3B8) : color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Valor atual", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              Text("Status", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(color: Color(AppColors.textPrimary), fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(status, style: TextStyle(color: isLoading ? Color(0xFF94A3B8) : color, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 20),
           if (fearGreedValue == null && fearGreedClassification == null && piCycleData == null && bitcoinDominanceData == null )
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'teste notificaçao',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                      SizedBox(width: 15),
                      ElevatedButton(
                        key: const Key('testeNotificacaoButton'),
                        onPressed: () {
                          NotificationService.showInfo(
                            title: 'Teste de Notificação',
                            body: 'O sistema de notificações está funcionando corretamente! 🚀',
                          );
                        },
                        child: Text('Teste Notificação'),
                      ),
                    ],
                  ),
                ),
          // Exibe o gauge apenas se for o Fear & Greed Index e tiver dados
          if (fearGreedValue != null && fearGreedClassification != null && !isLoading)
            Expanded(
              child: Container(
                key: const Key('medoGananciaCard'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(AppColors.cardIndicator),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: FearGreedGauge(
                          value: fearGreedValue!,
                          classification: fearGreedClassification!,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8), // Pequeno espaço entre container e créditos
                    // Créditos da API (clicável)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: InkWell(
                        onTap: () async {
                          final url = Uri.parse('https://alternative.me/crypto/fear-and-greed-index/');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(
                                'Fonte: Alternative.me Fear & Greed Index',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFF94A3B8).withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.open_in_new, size: 10, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          // Exibe o widget do Pi Cycle Top se tiver dados
          else if (piCycleData != null && !isLoading)
            Expanded(
              child: Container(
                key: const Key('piCycleTopCard'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(AppColors.cardIndicator),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: PiCycleTopWidget(
                  sma111: piCycleData!.sma111,
                  sma350x2: piCycleData!.sma350x2,
                  distance: piCycleData!.distance,
                  status: piCycleData!.status,
                  message: piCycleData!.message,
                ),
              ),
            )
          // Exibe o widget da dominância do Bitcoin se tiver dados
          else if (bitcoinDominanceData != null && !isLoading)
            Expanded(
              child: Container(
                key: const Key('bitcoinDominanceCard'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(AppColors.cardIndicator),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: BitcoinDominanceWidget(
                  // Dados reais da API
                  dominance: bitcoinDominanceData!.dominance,
                  status: bitcoinDominanceData!.status,
                  message: bitcoinDominanceData!.message,
                  cycleProximity: bitcoinDominanceData!.cycleProximity,

                  // 🧪 MOCKS PARA TESTE - Descomente para testar cenários específicos

                  // 🛡️ MEDO EXTREMO (Dominância 70%+, Proximidade 0%)
                  /*  dominance: 75.0,
                  status: 'extreme_fear',
                  message: 'Medo Extremo - Fuga para Bitcoin',
                  cycleProximity: 0.0, */

                  // 📈 MEDO (Dominância 55-65%, Proximidade ~20%)
                  /* dominance: 60.0,
                  status: 'fear',
                  message: 'Medo - Preferência pelo Bitcoin',
                  cycleProximity: 25.0, */

                  // ⚖️ NEUTRO (Dominância 45-55%, Proximidade ~50%)
                  /* dominance: 50.0,
                  status: 'neutral',
                  message: 'Neutro - Equilíbrio no mercado',
                  cycleProximity: 50.0, */

                  // 🚀 GANÂNCIA (Dominância 35-45%, Proximidade ~75%)
                  /*  dominance: 40.0,
                  status: 'greed',
                  message: 'Ganância - Dinheiro indo para altcoins',
                  cycleProximity: 75.0, */

                  // 🌙 GANÂNCIA EXTREMA (Dominância <35%, Proximidade 100%)
                  /*   dominance: 30.0,
                  status: 'extreme_greed',
                  message: 'Ganância Extrema - Altseason',
                  cycleProximity: 100.0,
 */
                  // 🔥 ALTSEASON TOTAL (Dominância muito baixa, Altcoins dominando)
                  /*   dominance: 25.0,
                  status: 'extreme_greed',
                  message: 'Ganância Extrema - Altseason',
                  cycleProximity: 100.0, */
                ),
              ),
            )
          else if (isLoading)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(AppColors.cardIndicator),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFFFB800))),
              ),
            )
          else
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(AppColors.cardIndicator),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget para exibir resumo geral dos indicadores
class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(AppColors.cardColor),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: Color(0xFFFFB800), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Análise Geral',
                      style: TextStyle(color: Color(AppColors.textPrimary), fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tendência lateral com sinais mistos. RSI neutro sugere possível acumulação.',
                      style: TextStyle(color: Color(AppColors.textSecondary), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                'NEUTRO',
                style: TextStyle(color: Color(0xFFFFB800), fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 8),
          // Atribuição das fontes de dados
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.source, size: 12, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                'Dados fornecidos por: CoinGecko API, Alternative.me',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
