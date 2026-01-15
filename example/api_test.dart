import 'package:btc_cycle_monitor/features/home/data/api/coingecko_api.dart';

/// Exemplo simples para testar a API do CoinGecko
void main() async {
  final api = CoinGeckoApi();
  
  try {
    print('🔄 Buscando preço do Bitcoin...');
    
    final bitcoinPrice = await api.getBitcoinPrice();
    
    print('✅ Dados obtidos com sucesso!');
    print('💰 Preço BTC/USD: \$${bitcoinPrice.usd.toStringAsFixed(2)}');
    print('💰 Preço BTC/BRL: R\$${bitcoinPrice.brl.toStringAsFixed(2)}');
    
  } catch (e) {
    print('❌ Erro ao buscar dados: $e');
  } finally {
    api.dispose();
  }
}