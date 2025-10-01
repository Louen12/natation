import 'package:natation/models/bay_level.dart';

class BayVMAService {
  double vitesseDepart = 8.0;
  double increment = 0.5;
  Duration dureePalier = Duration(minutes: 1);

  Baylevel getLevel(int numero) {
    double vitesse  = vitesseDepart + (increment * (numero - 1));
    return Baylevel(numero: numero, vitesse: vitesse, duree: dureePalier);
  }
}