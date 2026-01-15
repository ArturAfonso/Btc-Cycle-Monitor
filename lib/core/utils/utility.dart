import 'package:all_validations_br/all_validations_br.dart';
import 'package:btc_cycle_monitor/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:toast/toast.dart';

class Utility {
  static String returnOnlyNumbers(String txt) {
    return AllValidations.removeCharacters(txt);
  }

  /* static void unfocusTextField({BuildContext? contexto}) {
    if (contexto == null) {
      FocusScope.of(Get.context!).unfocus();
      FocusScope.of(Get.overlayContext!).unfocus();
    } else {
      FocusScope.of(contexto).unfocus();
    }
  } */

  static FormFieldValidator compare(TextEditingController? valueEC, String message) {
    return (value) {
      final valueCompare = valueEC?.text ?? '';
      if (value == null || (value != null && value != valueCompare)) {
        return message;
      }
      return null;
    };
  }

  String priceToCurrency(double price, {String? fiat}) {
    //fiat == 'BRL' ? fiat = 'pt_BR' : fiat = 'en_US';
    NumberFormat numberFormat = NumberFormat.decimalPattern();
    String result = numberFormat.format(price);
    String priceFormated = '';
    if (fiat != null) {
      priceFormated = _getCurrencySymbol(fiat) + result;
    }

    return priceFormated;
  }

  String _getCurrencySymbol(String currencyCode) {
    // Mapa constante que associa o código da moeda ao seu símbolo
    const Map<String, String> currencySymbolMap = {
      'USD': '\$', // Dólar Americano
      'EUR': '€', // Euro
      'BRL': 'R\$', // Real Brasileiro
      'GBP': '£', // Libra Esterlina
      'JPY': '¥', // Iene Japonês
    };

    // Tenta obter o símbolo.
    // O .?? retorna um valor padrão (ex: string vazia) se a chave não for encontrada.
    String result = currencySymbolMap[currencyCode] ?? '';
    return result;
  }

  void showToast({required String message, bool isError = false}) {
    /*  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: isError ? Colors.red : Colors.white,
      textColor: isError ? Colors.white : Colors.black,
      fontSize: 14,
    ); */
    Toast.show(
      message,
      duration: Toast.lengthShort,
      gravity: Toast.bottom,
      backgroundColor: isError ? Color(AppColors.errorColor) : Colors.white,
      textStyle: TextStyle(fontSize: 14, color: isError ? Colors.white : Colors.black),

      // webTexColor: isError ? Colors.white : Colors.black,
    );
  }

  String formatDateTime(DateTime dateTime) {
    initializeDateFormatting();

    DateFormat dateFormat = DateFormat.yMd('pt_BR').add_Hm();
    return dateFormat.format(dateTime);
  }
}
