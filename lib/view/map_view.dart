import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_travel_helper/directions_service.dart';
import 'package:flutter_travel_helper/nearby_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_travel_helper/bloc/auto_complete/auto_complete_bloc.dart';
import 'package:flutter_travel_helper/bloc/marker/marker_cubit.dart';
import 'package:flutter_travel_helper/repository/place_search_service.dart';
import 'package:flutter_travel_helper/view/widgets/search_result_item.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_travel_helper/models/place/nearby_response.dart';
import 'package:location/location.dart' as location;
import 'package:flutter_travel_helper/view/side_navigation_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class NearByPlacesScreen extends StatefulWidget {
  const NearByPlacesScreen({Key? key}) : super(key: key);

  @override
  State<NearByPlacesScreen> createState() => _NearByPlacesScreenState();
}


class _NearByPlacesScreenState extends State<NearByPlacesScreen> {
  String apiKey = "AIzaSyCtDZe1bsOKTMKwId3f9oggIaHb8h2sakw";
  String radius = "1500";
  double latitude = 0;
  double longitude = 0;
  double _minRating = 0;
  bool _onlyOpenPlaces = false;

  NearbyPlacesResponse nearbyPlacesResponse = NearbyPlacesResponse();

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  void _getLocation() async {
    location.Location loc = location.Location();
    bool _serviceEnabled;
    location.PermissionStatus _permissionGranted;
    location.LocationData? _locationData;

    _serviceEnabled = await loc.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await loc.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await loc.hasPermission();
    if (_permissionGranted == location.PermissionStatus.denied) {
      _permissionGranted = await loc.requestPermission();
      if (_permissionGranted != location.PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await loc.getLocation();
    setState(() {
      latitude = _locationData!.latitude!;
      longitude = _locationData.longitude!;
    });
  }

  void getNearbyPlaces(String type) async {
    var url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=$radius&type=$type&key=$apiKey',
    );

    var response = await http.get(url);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      List<dynamic> results = data['results'];

      List<Results> filteredResults = results
          .map((place) => Results.fromJson(place))
          .where((result) =>
      result.rating != null &&
          result.rating! >= _minRating &&
          (!_onlyOpenPlaces || (result.openingHours?.openNow ?? false)))
          .toList();

      setState(() {
        nearbyPlacesResponse = NearbyPlacesResponse(results: filteredResults, status: data['status']);
      });
    } else {
      // Handle error
      print('Failed to load nearby places: ${response.statusCode}');
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Places'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Find Nearby Places',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Only Open Places",
                    style: TextStyle(fontSize: 16),
                  ),
                  Switch(
                    value: _onlyOpenPlaces,
                    activeColor: Colors.deepPurple,
                    onChanged: (value) {
                      setState(() {
                        _onlyOpenPlaces = value;
                      });
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    "Minimum Rating: ",
                    style: TextStyle(fontSize: 16),
                  ),
                  Expanded(
                    child: Slider(
                      value: _minRating,
                      min: 0,
                      max: 5,
                      divisions: 5,
                      activeColor: Colors.deepPurple,
                      label: _minRating.toString(),
                      onChanged: (value) {
                        setState(() {
                          _minRating = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'onlyOpenPlaces': _onlyOpenPlaces,
                      'minRating': _minRating,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white, // Change button background color for contrast
                    onPrimary: Colors.deepPurple, // Change text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.deepPurple), // Add border color
                    ),
                  ),
                  child: const Text(
                    "Apply Filters",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Make the text bold
                      color: Colors.deepPurple, // Ensure text color is set
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (nearbyPlacesResponse.results != null)
                for (int i = 0; i < nearbyPlacesResponse.results!.length; i++)
                  if (_filterPlace(nearbyPlacesResponse.results![i]))
                    nearbyPlacesWidget(nearbyPlacesResponse.results![i]),
            ],
          ),
        ),
      ),
    );
  }






  bool _filterPlace(Results result) {
    bool isOpen = !_onlyOpenPlaces || (result.openingHours?.openNow ?? false);
    bool hasMinRating = result.rating != null && result.rating! >= _minRating;
    return isOpen && hasMinRating;
  }


  Widget nearbyPlacesWidget(Results results) {
    bool isOpen = results.openingHours?.openNow ?? false;

    return InkWell(
      onTap: () async {
        print('Tapped on ${results.name}');
        // Ensure AutoCompleteBloc logic is correct
        context.read<AutoCompleteBloc>().add(const TextChanged(text: ''));

        // Print statement to debug findAncestorStateOfType
        var mapViewState = context.findAncestorStateOfType<_MapViewState>();
        if (mapViewState != null) {
          mapViewState._onPlaceSelected();
          print('Called _onPlaceSelected');
        } else {
          print('mapViewState is null');
        }

        // Ensure MarkerCubit logic is correct
        var markerCubit = context.read<MarkerCubit>();
        await markerCubit.selectPlace(results.placeId.toString());

        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    results.name!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      Text(
                        results.rating != null ? results.rating.toString() : 'N/A',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Text(
                    isOpen ? "Open" : "Closed",
                    style: TextStyle(
                      color: isOpen ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            if (results.reference != null)
              IconButton(
                icon: Icon(Icons.link),
                onPressed: () {
                  // Open restaurant website
                },
              ),
          ],
        ),
      ),
    );
  }
}



class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  bool _placeSelected = false;
  LatLng? _initialPosition; // Nullable to handle loading state
  bool _loadingLocation = true; // Add loading indicator variable
  String apiKey = "AIzaSyCtDZe1bsOKTMKwId3f9oggIaHb8h2sakw";
  late final DirectionsService _directionsService;
  Map<String, dynamic>? _directions;
  Set<Polyline>? _polyLines;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _waypoints = [];
  String _originalDestination = '';
  bool _onlyOpenPlaces = false;
  double _minRating = 0;
  String _selectedCategory = ''; // Variable to track the selected category

  @override
  void initState() {
    super.initState();
    _directionsService = DirectionsService(apiKey: apiKey);
    _getLocation();
  }
  void _launchGoogleMaps() async {
    // Check if the user is logged in
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Error: User not logged in');
      return;
    }

    String origin = '${_initialPosition?.latitude},${_initialPosition?.longitude}';
    String destination = _originalDestination;
    String waypoints =  _waypoints.map((wp) => wp['coordinates'] as String).join('|');

    String url = 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&waypoints=$waypoints&travelmode=driving';
    print('Generated URL: $url');

    // Save travel data to Firestore
    await _saveTravelData(user.uid, origin, destination, _waypoints);

    final Uri urlEncoded = Uri.parse(url);
    bool canLaunchUrl = await canLaunch(urlEncoded.toString());
    print('Can launch URL: $canLaunchUrl');
    if (canLaunchUrl) {
      await launchUrl(urlEncoded);
    } else {
      print('Error: Could not launch URL');
      throw 'Could not launch $url';
    }
  }

  Future<void> _saveTravelData(String userId, String origin, String destination, List<Map<String, dynamic>> waypoints) async {
    CollectionReference travels = FirebaseFirestore.instance.collection('travels');

    List<Map<String, dynamic>> formattedWaypoints = waypoints.map((wp) {
      return {
        'coordinates': wp['coordinates'],
        'type': wp['type'],
      };
    }).toList();

    Map<String, dynamic> travelData = {
      'userId': userId,
      'origin': origin,
      'destination': destination,
      'waypoints': formattedWaypoints,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await travels.add(travelData);
      print('Travel data saved successfully');
    } catch (e) {
      print('Error saving travel data: $e');
    }
  }

  String formatWaypoints(List<String> waypoints) {
    return waypoints.map((wp) => 'via:$wp').join('|');
  }

  void _addPlaceToRoute(Results result, String type) {
    final waypoint = LatLng(
        result.geometry!.location!.lat!, result.geometry!.location!.lng!);
    final waypointString = '${waypoint.latitude},${waypoint.longitude}';

    setState(() {
      _waypoints.add({
        'coordinates': waypointString,
        'type': type,
      });
    });

    // Call getDirections with the original destination and updated waypoints
    getDirections(_originalDestination, _waypoints.map((wp) => wp['coordinates'] as String).toList());
  }

  void _clearWaypoints() {
    setState(() {
      _waypoints.clear();
    });
  }

  List<Map<String, double>> decodePolyline(String polyline) {
    List<Map<String, double>> points = [];
    int index = 0,
        len = polyline.length;
    int lat = 0,
        lng = 0;

    while (index < len) {
      int b,
          shift = 0,
          result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add({"lat": lat / 1E5, "lng": lng / 1E5});
    }
    return points;
  }


  void getDirections(String destination, List<String> waypoints) async {
    try {
      location.LocationData loc = await location.Location().getLocation();
      LatLng origin;

      if (loc.latitude != null && loc.longitude != null) {
        origin = LatLng(loc.latitude!, loc.longitude!);

        String waypointsParam = waypoints.isNotEmpty ? '&waypoints=${waypoints
            .join('|')}' : '';
        String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${origin
            .latitude},${origin
            .longitude}&destination=$destination&key=$apiKey$waypointsParam';

        print('Request URL: $url'); // Log the request URL

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);

          if (data['routes'].isEmpty) {
            print('No routes found');
            return;
          }

          final points = decodePolyline(
              data['routes'][0]['overview_polyline']['points']);
          _polyLines = {};

          final List<LatLng> polylineCoordinates = points.map((point) {
            return LatLng(point['lat']!, point['lng']!);
          }).toList();

          setState(() {
            _polyLines!.add(
              Polyline(
                polylineId: PolylineId('route'),
                points: polylineCoordinates,
                color: Colors.blue,
                width: 5,
              ),
            );
          });

          LatLngBounds bounds = _getBounds(polylineCoordinates);
          context
              .read<MarkerCubit>()
              .controller
              .animateCamera(CameraUpdate.newLatLngBounds(bounds, 30));
        } else {
          print('Failed to load directions');
          print(response.body);
        }
      }
    } catch (e) {
      print('Error occurred while fetching directions: $e');
    }
  }

  LatLngBounds _getBounds(List<LatLng> polyline) {
    double southWestLat = polyline.first.latitude;
    double southWestLng = polyline.first.longitude;
    double northEastLat = polyline.first.latitude;
    double northEastLng = polyline.first.longitude;

    for (var point in polyline) {
      if (point.latitude < southWestLat) southWestLat = point.latitude;
      if (point.longitude < southWestLng) southWestLng = point.longitude;
      if (point.latitude > northEastLat) northEastLat = point.latitude;
      if (point.longitude > northEastLng) northEastLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(southWestLat, southWestLng),
      northeast: LatLng(northEastLat, northEastLng),
    );
  }

  void getNearbyMarkers(LatLng location, String placeType,
      {bool? isOpen, double? minRating}) async {
    _markers = {};
    var res = await NearbyService.getNearbyPlaces(placeType, location, 2000);
    if (res != null && res.results != null) {
      for (Results result in res.results!) {
        // Check if the place is open if isOpen is provided
        if (isOpen != null && result.openingHours != null &&
            result.openingHours!.openNow != isOpen) {
          continue; // Skip this result if it doesn't match the open status
        }

        // Check if the place's rating is above the minimum rating if minRating is provided
        if (minRating != null && result.rating != null &&
            result.rating! < minRating) {
          continue; // Skip this result if its rating is below the minimum rating
        }

        LatLng loc = LatLng(
            result.geometry!.location!.lat!, result.geometry!.location!.lng!);
        _markers.add(Marker(
          markerId: MarkerId(result.placeId!),
          position: loc,
          onTap: () {
            _showMarkerDetails(result);
          },
        ));
      }
    }
    setState(() {});
  }



  void _showMarkerDetails(Results result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(result.name ?? 'Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rating: ${result.rating?.toString() ?? 'N/A'}'),
                const SizedBox(height: 10),
                Text(
                  result.openingHours != null && result.openingHours!.openNow != null
                      ? (result.openingHours!.openNow!
                      ? "Status: Open"
                      : "Status: Closed")
                      : "Opening hours: Not available",
                  style: TextStyle(
                    color: result.openingHours != null && result.openingHours!.openNow != null
                        ? (result.openingHours!.openNow! ? Colors.green : Colors.red)
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text('Address: ${result.vicinity ?? 'Not available'}'),
                const SizedBox(height: 10),
                if (result.formattedPhoneNumber != null)
                  Text('Phone: ${result.formattedPhoneNumber ?? 'Not available'}'),
                const SizedBox(height: 10),
                if (result.photos != null && result.photos!.isNotEmpty)
                  Image.network(
                    'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${result.photos![0].photoReference}&key=$apiKey',
                    fit: BoxFit.cover,
                  ),
                const SizedBox(height: 10),
                if (result.website != null)
                  GestureDetector(
                    onTap: () {
                      _launchURL(result.website!);
                    },
                    child: Text(
                      'Visit Website',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                Navigator.of(context).pop();
                _addPlaceToRoute(result, result.types!.first);
              },
            ),
          ],
        );
      },
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _getLocation() async {
    try {
      location.Location loc = location.Location();
      bool _serviceEnabled;
      location.PermissionStatus _permissionGranted;
      location.LocationData? _locationData;

      _serviceEnabled = await loc.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await loc.requestService();
        if (!_serviceEnabled) {
          return;
        }
      }

      _permissionGranted = await loc.hasPermission();
      if (_permissionGranted == location.PermissionStatus.denied) {
        _permissionGranted = await loc.requestPermission();
        if (_permissionGranted != location.PermissionStatus.granted) {
          return;
        }
      }

      _locationData = await loc.getLocation();
      setState(() {
        _initialPosition =
            LatLng(_locationData!.latitude!, _locationData.longitude!);
        _loadingLocation = false; // Update loading indicator
      });
    } catch (e) {
      print("Error retrieving location: $e");
      setState(() {
        _loadingLocation = false; // Update loading indicator in case of error
      });
      // Handle the error appropriately, e.g., show an error message or retry
    }
  }

  void _onPlaceSelected() {
    setState(() {
      _placeSelected = true;
    });
  }

  void _onFABPressed() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NearByPlacesScreen()),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final markerCubit = context.read<MarkerCubit>();
    CameraPosition kDefaultPosition =
    const CameraPosition(target: LatLng(11.967375, 121.924812), zoom: 15);
    if (markerCubit.selectedMarker != null) {
      kDefaultPosition = CameraPosition(
          target: markerCubit.selectedMarker!.position, zoom: 15);
    }

    final kInitialPosition = _initialPosition != null
        ? CameraPosition(target: _initialPosition!, zoom: 15)
        : kDefaultPosition;

    final textController = TextEditingController();

    return Scaffold(
      drawer: Navigationdrawer(),
      appBar: AppBar(
        title: const Text('App Route'),
      ),
      body: _loadingLocation
          ? Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          MapWidget(
            kInitialPosition: kInitialPosition,
            polylines: _polyLines,
            markers: _markers,
          ),
          if (_placeSelected)
            Positioned(
              bottom: 40, // Adjusted bottom position
              left: 10,
              right: 10,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    // Add padding below the buttons
                    child: Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                icon: Icons.restaurant,
                                label: 'Restaurants',
                                category: 'restaurant',
                              ),
                              _buildActionButton(
                                icon: Icons.local_mall,
                                label: 'Malls',
                                category: 'shopping_mall',
                              ),
                              _buildActionButton(
                                icon: Icons.park,
                                label: 'Parks',
                                category: 'park',
                              ),
                              _buildActionButton(
                                icon: Icons.local_gas_station,
                                label: 'Gas Stations',
                                category: 'gas_station',
                              ),
                              _buildActionButton(
                                icon: Icons.local_hospital,
                                label: 'Hospitals',
                                category: 'hospital',
                              ),
                              _buildActionButton(
                                icon: Icons.local_pharmacy,
                                label: 'Pharmacies',
                                category: 'pharmacy',
                              ),
                              _buildActionButton(
                                icon: Icons.local_grocery_store,
                                label: 'Grocery Stores',
                                category: 'grocery_store',
                              ),
                              // Add more buttons as needed
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _launchGoogleMaps,
                          child: const Text('Open in Google Maps'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          PredictionList(
            textController: textController,
            onPlaceSelected: (place) {
              _onPlaceSelected();
              setState(() {
                _placeSelected = true;
              });
            },
          ),
          if (_placeSelected)
            Positioned(
              top: 80,
              // Adjust this value as needed to place below the search bar
              left: 10,
              child: FloatingActionButton(
                onPressed: () async {
                  final filters = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NearByPlacesScreen()),
                  );
                  if (filters != null) {
                    applyFilters(filters['onlyOpenPlaces'],
                        filters['minRating']);
                  }
                },
                child: Icon(Icons.filter_alt),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String category,
  }) {
    final isSelected = _selectedCategory == category;

    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _selectedCategory = category;
        });
        _fetchNearbyPlaces(category);
      },
      icon: Icon(icon, color: isSelected ? Colors.white : Colors.black),
      label: Text(
        label,
        style: TextStyle(color: isSelected ? Colors.white : Colors.black),
      ),
      style: ElevatedButton.styleFrom(
        primary: isSelected ? Colors.blue : Colors.grey[200],
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        textStyle: const TextStyle(fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void applyFilters(bool onlyOpen, double minRating) {
    setState(() {
      _onlyOpenPlaces = onlyOpen;
      _minRating = minRating;
    });
    // Call _fetchNearbyPlaces with the selected category
    if (_selectedCategory.isNotEmpty) {
      _fetchNearbyPlaces(_selectedCategory);
    }
  }

  void _fetchNearbyPlaces(String placeType) {
    if (_polyLines != null && _polyLines!.isNotEmpty) {
      final polylineCoordinates = _polyLines!.first.points;

      // Calculate indices for quarter and three-quarters points
      final quarterIndex = (polylineCoordinates.length / 4).round();
      final threeQuarterIndex = (3 * polylineCoordinates.length / 4).round();

      if (_onlyOpenPlaces) {
        // Fetch only open places if _onlyOpenPlaces is true
        getNearbyMarkers(
          polylineCoordinates.last,
          placeType,
          isOpen: true,
          minRating: _minRating,
        );
        getNearbyMarkers(
          polylineCoordinates[((polylineCoordinates.length - 1) / 2).round()],
          placeType,
          isOpen: true,
          minRating: _minRating,
        );
        getNearbyMarkers(
          polylineCoordinates[quarterIndex],
          placeType,
          isOpen: true,
          minRating: _minRating,
        );
        getNearbyMarkers(
          polylineCoordinates[threeQuarterIndex],
          placeType,
          isOpen: true,
          minRating: _minRating,
        );
      } else {
        // Fetch all places regardless of open status
        getNearbyMarkers(
          polylineCoordinates.last,
          placeType,
          isOpen: null, // Pass null to get all places
          minRating: _minRating,
        );
        getNearbyMarkers(
          polylineCoordinates[((polylineCoordinates.length - 1) / 2).round()],
          placeType,
          isOpen: null, // Pass null to get all places
          minRating: _minRating,
        );
        getNearbyMarkers(
          polylineCoordinates[quarterIndex],
          placeType,
          isOpen: null, // Pass null to get all places
          minRating: _minRating,
        );
        getNearbyMarkers(
          polylineCoordinates[threeQuarterIndex],
          placeType,
          isOpen: null, // Pass null to get all places
          minRating: _minRating,
        );
      }
    }
  }

}
class MapWidget extends StatelessWidget {
  const MapWidget({
    Key? key,
    required this.kInitialPosition,
    this.polylines,
    this.markers,
  }) : super(key: key);

  final CameraPosition kInitialPosition;
  final Set<Polyline>? polylines;
  final Set<Marker>? markers;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarkerCubit, MarkerState>(
      builder: (context, state) {
        return GoogleMap(
          onMapCreated: (controller) {
            context.read<MarkerCubit>().controller = controller;
          },
          // markers: context.read<MarkerCubit>().mapMarkers,
          markers: markers ?? {},
          initialCameraPosition: kInitialPosition,
          myLocationEnabled: true,
          polylines: polylines ?? {},
        );
      },
    );
  }
}
class PredictionList extends StatelessWidget {
  const PredictionList({
    required this.textController,
    required this.onPlaceSelected,
    Key? key,
  }) : super(key: key);

  final TextEditingController textController;
  final void Function(dynamic) onPlaceSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.06,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: TextFormField(
              controller: textController,
              autocorrect: false,
              onChanged: (text) {
                context.read<AutoCompleteBloc>().add(TextChanged(text: text));
              },
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Colors.black54,
                  ),
                  onPressed: () {
                    context.read<AutoCompleteBloc>().add(const TextChanged(text: ""));
                    textController.clear();
                  },
                ),
                prefixIcon: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          SearchResults(
            onPlaceSelected: onPlaceSelected,
          ),
        ],
      ),
    );
  }
}

class SearchResults extends StatelessWidget {
  const SearchResults({
    required this.onPlaceSelected,
    Key? key,
  }) : super(key: key);

  final void Function(dynamic) onPlaceSelected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AutoCompleteBloc, AutoCompleteState>(
      builder: (context, state) {
        switch (state.runtimeType) {
          case AutoCompleteEmpty:
            return const SizedBox.shrink();
          case AutoCompleteSelectedPlace:
            return const SizedBox.shrink();
          case AutoCompleteError:
            return Text((state as AutoCompleteError).error);
          case AutoCompleteLoading:
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          case AutoCompleteSuccess:
            return (state as AutoCompleteSuccess).items.isEmpty
                ? const Text('No Result')
                : Expanded(
              child: ListView.builder(
                itemCount: (state as AutoCompleteSuccess).items.length,
                itemBuilder: (BuildContext context, int index) {
                  return SearchResultItemCard(
                    itemText: (state as AutoCompleteSuccess).items[index].structuredFormatting!,
                    onTap: () async {
                      final mapState = context.findAncestorStateOfType<_MapViewState>();
                      await context.read<MarkerCubit>().selectPlace((state as AutoCompleteSuccess).items[index].placeId.toString());
                      context.read<AutoCompleteBloc>().add(const TextChanged(text: ''));
                      mapState!._onPlaceSelected();
                      mapState.setState(() {
                        // Clear waypoints when a new destination is chosen
                        mapState._clearWaypoints();

                        // Set the new destination
                        mapState._originalDestination = (state as AutoCompleteSuccess).items[index].structuredFormatting!.mainText!;
                      });

                      // Call getDirections with the new dest
                      mapState.getDirections(
                          (state as AutoCompleteSuccess).items[index].structuredFormatting!.mainText!, []);

                      // Notify that a place has been selected
                      onPlaceSelected((state as AutoCompleteSuccess).items[index]);
                    },
                  );
                },
              ),
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

