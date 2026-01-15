import 'dart:io';
import 'lib/features/home/data/api/coingecko_api.dart';

void main() async {
  print('🚀 Testando API do CoinGecko...');
  
  final api = CoinGeckoApi();
  
  try {
    print('📊 Buscando preço atual do Bitcoin...');
    final currentPrice = await api.getBitcoinPrice();
    print('✅ Preço atual: \$${currentPrice.usd.toStringAsFixed(2)}');
    
    print('\n📈 Buscando dados históricos (1D)...');
    final historicalData = await api.getBitcoinHistoricalData(days: '1');
    print('✅ Dados históricos recebidos: ${historicalData.chartData.length} pontos');
    print('   Primeiro valor: \$${historicalData.chartData.first.toStringAsFixed(2)}');
    print('   Último valor: \$${historicalData.chartData.last.toStringAsFixed(2)}');
    
    print('\n📈 Buscando dados históricos (1W)...');
    final weekData = await api.getBitcoinHistoricalData(days: '7');
    print('✅ Dados históricos 1W: ${weekData.chartData.length} pontos');
    
  } catch (e) {
    print('❌ Erro na API: $e');
  }
  
  print('\n🏁 Teste concluído!');
  exit(0);
}