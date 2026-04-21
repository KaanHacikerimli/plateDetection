import 'dart:io';
import 'dart:convert'; // JSON verisini işlemek için
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // API iletişimi için
import 'package:geolocator/geolocator.dart'; // Konum almak için eklendi

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoPlate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A237E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFF3949AB),
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)),
          prefixIconColor: Colors.grey[600],
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// --- GİRİŞ EKRANI (DATABASE BAĞLANTILI) ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _girisYap() async {
    setState(() { _isLoading = true; });

    try {
      var url = Uri.parse("http://10.222.114.216:8000/login");

      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _usernameController.text,
          "password": _passwordController.text,
        }),
      );

      setState(() { _isLoading = false; });

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(username: jsonResponse['username']),
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(jsonResponse['message']), backgroundColor: Colors.red));
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sunucu hatası veya IP yanlış!"), backgroundColor: Colors.red));
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      print("Hata: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bağlantı hatası! Sunucu açık mı?"), backgroundColor: Colors.red));
    }
  }

  void _kayitOlSayfasinaGit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: size.height * 0.35,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "AutoPlate",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Akıllı Plaka Tanıma Sistemi",
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Hoş Geldiniz", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)), textAlign: TextAlign.center),
                  const SizedBox(height: 30),
                  TextField(controller: _usernameController, decoration: const InputDecoration(labelText: "Kullanıcı Adı", prefixIcon: Icon(Icons.person_outline))),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Şifre",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () { setState(() { _isPasswordVisible = !_isPasswordVisible; }); },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _girisYap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Giriş Yap", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Hesabın yok mu?", style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: _kayitOlSayfasinaGit,
                        child: const Text("Kayıt Ol", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- KAYIT OL EKRANI (DATABASE BAĞLANTILI) ---
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _kayitIslemi() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifreler uyuşmuyor!"), backgroundColor: Colors.red));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      var url = Uri.parse("http://10.222.114.216:8000/register");

      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _usernameController.text,
          "password": _passwordController.text,
        }),
      );

      setState(() { _isLoading = false; });

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt Başarılı! Giriş yapabilirsiniz."), backgroundColor: Colors.green));
          Navigator.pop(context);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(jsonResponse['message']), backgroundColor: Colors.red));
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sunucu hatası"), backgroundColor: Colors.red));
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      print("Hata: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bağlantı hatası! Sunucu açık mı?"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A237E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: size.height * 0.25,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: const Center(
                child: Text("Aramıza Katıl", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Yeni Hesap Oluştur", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)), textAlign: TextAlign.center),
                  const SizedBox(height: 30),
                  TextField(controller: _usernameController, decoration: const InputDecoration(labelText: "Kullanıcı Adı", prefixIcon: Icon(Icons.person_add_alt))),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Şifre",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () { setState(() { _isPasswordVisible = !_isPasswordVisible; }); },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Şifre Tekrar",
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () { setState(() { _isConfirmPasswordVisible = !_isConfirmPasswordVisible; }); },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _kayitIslemi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Kayıt Ol", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// İşlemi tamamlanan plakaları burada tutacağız
Set<String> cekilenPlakalar = {};
// --- ANA SAYFA ---
class DashboardScreen extends StatefulWidget {
  final String username;
  const DashboardScreen({super.key, required this.username});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  List<Map<String, String>> sonOkunanlar = [];

  // --- API VE MAIL AYARLARI ---
  final String _sendGridApiKey = "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";
  final String _onayliMail = "kaanadns@gmail.com"; // Değiştirin
  final String _cekiciMail = "kaanhckrmli@gmail.com"; // Değiştirin

  @override
  void initState() {
    super.initState();
    _gecmisiYukle();
  }

  // --- MAIL GÖNDERME FONKSİYONU ---
  Future<void> _araciCekBildir(String plaka) async {
    setState(() { _isLoading = true; });
    try {
      // 1. ADIM: KONUM SERVİSİ KONTROLÜ
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw "GPS Kapalı. Lütfen telefonun konumunu açın.";
      }

      // 2. ADIM: İZİN KONTROLÜ
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw "Konum izni reddedildi.";
        }
      }

      // 3. ADIM: KONUM ALMA (Hızlı ve garantili yöntem)
      // Eğer iç mekandaysan 'high' yerine 'balanced' daha kolay sonuç verir
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15)
      );

      // Değişken kullanımı: ${position.latitude}
      String mapLink = "https://www.google.com/maps?q=${position.latitude},${position.longitude}";

      // 4. ADIM: SENDGRID MAIL ATMA
      var response = await http.post(
        Uri.parse("https://api.sendgrid.com/v3/mail/send"),
        headers: {
          "Authorization": "Bearer $_sendGridApiKey",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "personalizations": [
            {
              "to": [{"email": _cekiciMail}]
            }
          ],
          "from": {"email": _onayliMail},
          "subject": "ARAÇ ÇEKME TALEBİ - $plaka",
          "content": [
            {
              "type": "text/plain",
              "value": "Merhaba,\n\n$plaka plakalı araç için çekici talebi oluşturuldu.\nKonum: $mapLink"
            }
          ]
        }),
      );

      setState(() { _isLoading = false; });

      if (response.statusCode == 202) {
        setState(() {
          // Plakayı "çekilenler" listesine ekle ki bir daha basılmasın
          cekilenPlakalar.add(plaka);
        });
        _mesajGoster("Başarılı! Çekiciye bildirim gönderildi.", Colors.green);
      } else {
        // SendGrid hata verirse hatanın gövdesini yakalıyoruz
        throw "Mail Hatası: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      // Ekranda hatanın gerçek sebebini gösterir:
      _hataGoster("DETAY: $e");
      print("LOG: $e");
    }
  }

  // --- PLAKA TIKLANINCA AÇILACAK MENÜ ---
  void _secenekleriGoster(String plaka) {
    // Bu plaka daha önce çekildi mi?
    bool zatenCekildi = cekilenPlakalar.contains(plaka);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(plaka, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E))),
            const SizedBox(height: 10),
            const Divider(),
            ListTile(
              leading: Icon(Icons.local_shipping,
                  color: zatenCekildi ? Colors.grey : Colors.redAccent),
              title: Text(
                zatenCekildi ? "Bu Araç Zaten Çekildi" : "Aracı Çek (Mail Gönder)",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: zatenCekildi ? Colors.grey : Colors.black
                ),
              ),
              // Eğer çekildiyse tıklama özelliğini kapatıyoruz (null yaparak)
              onTap: zatenCekildi ? null : () {
                Navigator.pop(context);
                _araciCekBildir(plaka);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text("İptal"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _gecmisiYukle() async {
    try {
      var url = Uri.parse("http://10.222.114.216:8000/get_history/${widget.username}");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() {
            sonOkunanlar = List<Map<String, String>>.from(
                jsonResponse['history'].map((item) => {
                  "plaka": item['plaka'].toString(),
                  "saat": item['saat'].toString()
                })
            );
          });
        }
      }
    } catch (e) {
      print("Geçmiş yüklenirken hata: $e");
    }
  }

  Future<void> _veritabaninaKaydet(String plaka, String saat) async {
    try {
      var url = Uri.parse("http://10.222.114.216:8000/add_record");

      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": widget.username,
          "plaka": plaka,
          "saat": saat
        }),
      );

      setState(() {
        sonOkunanlar.insert(0, {"plaka": plaka, "saat": saat});
      });
    } catch (e) {
      _hataGoster("Veritabanına kaydedilemedi.");
    }
  }

  Future<void> _resimSecVeGonder(ImageSource kaynak) async {
    try {
      final XFile? photo = await _picker.pickImage(source: kaynak, imageQuality: 100);

      if (photo != null) {
        setState(() { _isLoading = true; });
        var uri = Uri.parse("http://10.222.114.216:8000/predict");
        var request = http.MultipartRequest('POST', uri);
        request.files.add(await http.MultipartFile.fromPath('file', photo.path));

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        setState(() { _isLoading = false; });

        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          if (jsonResponse['success'] == true) {
            _sonucPenceresiGoster(jsonResponse['plaka'], File(photo.path));
          } else {
            _hataGoster("Plaka okunamadı: ${jsonResponse['message']}");
          }
        } else {
          _hataGoster("Sunucu Hatası: ${response.statusCode}");
        }
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      _hataGoster("Bağlantı hatası!");
    }
  }

  void _sonucPenceresiGoster(String plaka, File resim) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Plaka Bulundu!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(resim, height: 150, fit: BoxFit.cover)),
            const SizedBox(height: 15),
            Text(plaka, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            const Text("Listeye kaydedilsin mi?"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.red))),
          ElevatedButton(
            onPressed: () {
              String suankiSaat = "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}";
              _veritabaninaKaydet(plaka, suankiSaat);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  void _hataGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: Colors.red));
  }

  void _mesajGoster(String mesaj, Color renk) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: renk));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: const Text("AutoPlate Panel", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
          )
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Merhaba, ${widget.username} 👋", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                const Text("Plaka tanımaya başlamak için bir yöntem seçin.", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildActionCard(context, icon: Icons.camera_alt_rounded, title: "Fotoğraf Çek", color: Colors.orange, onTap: () => _resimSecVeGonder(ImageSource.camera)),
                    const SizedBox(width: 16),
                    _buildActionCard(context, icon: Icons.photo_library_rounded, title: "Galeriden Seç", color: Colors.blue, onTap: () => _resimSecVeGonder(ImageSource.gallery)),
                  ],
                ),
                const SizedBox(height: 30),
                const Text("Son Okunanlar (İşlem için plakaya tıklayın)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                const SizedBox(height: 10),
                Expanded(
                  child: sonOkunanlar.isEmpty
                      ? const Center(child: Text("Henüz plaka okunmadı.", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                    itemCount: sonOkunanlar.length,
                    itemBuilder: (context, index) {
                      String plaka = sonOkunanlar[index]["plaka"]!;
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          // Yeni hali:
                          child: ListTile(
                            onTap: () => _secenekleriGoster(plaka),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF1A237E).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)
                              ),
                              child: const Icon(Icons.directions_car, color: Color(0xFF1A237E)),
                            ),
                            title: Text(plaka, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Okunma Saati: ${sonOkunanlar[index]["saat"]}"),

                            // DEĞİŞEN KISIM BURASI:
                            trailing: cekilenPlakalar.contains(plaka)
                                ? const Icon(Icons.lock, color: Colors.orange, size: 24) // Çekildiyse Turuncu Kilit
                                : const Icon(Icons.more_vert), // Çekilmediyse Üç Nokta
                          ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          splashColor: color.withOpacity(0.2),
          child: Container(
            height: 150,
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 40, color: color)),
                const SizedBox(height: 15),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}