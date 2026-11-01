enum DeliveryCity {
  doha('Doha'),
  rayyan('Rayyan'),
  umSalal('Um Salal'),
  wakrah('Wakrah'),
  khour('Khour'),
  alDaayen('AL Daayen'),
  westBay('West Bay'),
  thePearl('The Pearl'),
  lusail('Lusail'),
  alSadd('Al Sadd'),
  binMahmoud('Bin Mahmoud'),
  najma('Najma'),
  alMansoura('Al Mansoura'),
  oldAirport('Old Airport'),
  alHilal('Al Hilal'),
  abuHamour('Abu Hamour'),
  ainKhaled('Ain Khaled'),
  alWaab('Al Waab'),
  muaither('Muaither'),
  madinatKhalifa('Madinat Khalifa'),
  duhail('Duhail'),
  alGharrafa('Al Gharrafa'),
  alThumama('Al Thumama'),
  alDafna('Al Dafna'),
  alKheesa('Al Kheesa'),
  alWukair('Al Wukair'),
  izghawa('Izghawa'),
  azizia('Azizia'),
  alMarkhiya('Al Markhiya'),
  ummGhuwailina('Umm Ghuwailina'),
  alMuntazah('Al Muntazah'),
  alNasr('Al Nasr');

  const DeliveryCity(this.value);

  /// Stable API/storage value, independent of the language used to display it.
  final String value;

  static DeliveryCity? fromValue(String value) {
    var name = value.trim().toLowerCase();
    name =
        const {
          'al rayyan': 'rayyan',
          'al wakrah': 'wakrah',
          'al khor': 'khour',
          'al khour': 'khour',
          'khor': 'khour',
          'umm salal': 'um salal',
        }[name] ??
        name;
    for (final city in values) {
      if (city.value.toLowerCase() == name) return city;
    }
    return null;
  }
}
