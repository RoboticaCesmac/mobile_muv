import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../models/activity.dart';
import '../services/user_profile_service.dart';
import '../screens/recording_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _userProfileService = UserProfileService();
  Future<UserProfile?>? _userProfileFuture;
  final List<Activity> _activities = Activity.getMockActivities();
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _userProfileService.getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Seção do perfil do usuário
            _buildUserProfileSection(),
            
            // Seção de atividades
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Atividade',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.grid_view),
                              onPressed: () {},
                              color: Colors.grey,
                            ),
                            IconButton(
                              icon: const Icon(Icons.view_list),
                              onPressed: () {},
                              color: const Color(0xFF004341),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Lista de atividades
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        return _buildActivityCard(_activities[index]);
                      },
                    ),
                  ),
                  
                  // Indicadores de página
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _activities.length,
                        (index) => Container(
                          width: 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? const Color(0xFF004341)
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Início', true),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecordingPage()),
                  );
                },
                child: _buildNavItem(Icons.fiber_manual_record, 'Gravar', false),
              ),
              _buildNavItem(Icons.settings, 'Config', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<UserProfile?>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Erro: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Dados não disponíveis'),
            );
          }

          final userProfile = snapshot.data!;

          return Column(
            children: [
              Row(
                children: [
                  // Avatar do usuário
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(userProfile.avatar.avatarUrl),
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(width: 16),
                  
                  // Informações do usuário
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, ${userProfile.userName}!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Barra de progresso e ícone de level na mesma linha
                        Row(
                          children: [
                            // Barra de progresso baseada nos pontos atuais e pontos para o próximo nível
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  // Calcula o progresso: pontos atuais / pontos necessários para o próximo nível
                                  value: userProfile.profileData.totalPoints / 
                                      userProfile.profileData.totalPointsOfNextLevel,
                                  backgroundColor: Colors.grey[200],
                                  color: const Color(0xFF18694F),
                                  minHeight: 12, // Aumentando altura da barra
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Ícone de level com tamanho aumentado
                            userProfile.profileData.currentLevelIcon != null
                                ? Image.network(
                                    userProfile.profileData.currentLevelIcon!,
                                    width: 32, // Aumentado de 24 para 32
                                    height: 32, // Aumentado de 24 para 32
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.nature,
                                        color: Colors.green[400],
                                        size: 32, // Aumentado de 24 para 32
                                      );
                                    },
                                  )
                                : Icon(
                                    Icons.nature,
                                    color: Colors.green[400],
                                    size: 32, // Aumentado de 24 para 32
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Estatísticas do usuário
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.star,
                    'Pontos',
                    '${userProfile.profileData.totalPoints}',
                    Colors.green,
                  ),
                  _buildStatItem(
                    Icons.place,
                    'Distância',
                    '${userProfile.profileData.distanceTraveled.toInt()}km',
                    Colors.orange,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String title, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Activity activity) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título da atividade
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: _getColorForActivityType(activity.type),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    activity.type,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.straighten, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.distance}km',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Detalhes da atividade
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Horário de início
                  Row(
                    children: [
                      const Text(
                        'Início',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateFormat.format(activity.startTime),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Horário de fim
                  Row(
                    children: [
                      const Text(
                        'Fim',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateFormat.format(activity.endTime),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Mapa
            Container(
              height: 110,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://maps.googleapis.com/maps/api/staticmap?center=São+Paulo&zoom=13&size=600x300&maptype=roadmap',
                  ),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 14.0),
            ),
            
            // Estatísticas da atividade
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.co2, color: Colors.green, size: 18),
                      ),
                      const SizedBox(width: 4),
                      Text('${activity.co2PerKm} kg/CO2'),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star, color: Colors.orange, size: 18),
                      ),
                      const SizedBox(width: 4),
                      Text('${activity.points} Pontos'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getColorForActivityType(String type) {
    if (type.contains('carro')) {
      return Colors.red.shade400;
    } else if (type.contains('Ônibus')) {
      return Colors.amber.shade700;
    } else if (type.contains('Bicicleta')) {
      return Colors.green.shade400;
    }
    return Colors.blue;
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF004341) 
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey,
            size: 20,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF004341) : Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
} 