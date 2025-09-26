import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/zone_model.dart';
import '../models/venue_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_nav_bar.dart';
import '../widgets/venue_card.dart';
import 'venue_detail_screen.dart';

class ZoneVenuesScreen extends StatefulWidget {
  final ZoneModel zone;

  const ZoneVenuesScreen({Key? key, required this.zone}) : super(key: key);

  @override
  _ZoneVenuesScreenState createState() => _ZoneVenuesScreenState();
}

class _ZoneVenuesScreenState extends State<ZoneVenuesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          CustomNavBar(
            title: widget.zone.name,
            user: user,
            showBackButton: true,
          ),

          // Buscador
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar local...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Lista de locales
          Expanded(
            child: StreamBuilder<List<VenueModel>>(
              stream: Provider.of<DatabaseService>(context).getVenuesByZone(widget.zone.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_bar,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay locales en esta zona',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final venues = snapshot.data!.where((venue) {
                  return venue.name.toLowerCase().contains(_searchQuery);
                }).toList();

                if (venues.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No se encontraron locales',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: venues.length,
                  itemBuilder: (context, index) {
                    final venue = venues[index];
                    return VenueCard(
                      venue: venue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VenueDetailScreen(venue: venue),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
