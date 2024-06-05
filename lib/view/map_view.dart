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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Places'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                getNearbyPlaces("restaurant");
              },
              child: const Text("nearby restaurant"),
            ),
            ElevatedButton(
              onPressed: () {
                getNearbyPlaces("park");
              },
              child: const Text("nearby parks"),
            ),
            ElevatedButton(
              onPressed: () {
                getNearbyPlaces("shopping_mall");
              },
              child: const Text("nearby malls"),
            ),
            if (nearbyPlacesResponse.results != null)
              for (int i = 0; i < nearbyPlacesResponse.results!.length; i++)
                nearbyPlacesWidget(nearbyPlacesResponse.results![i])
          ],
        ),
      ),
    );
  }

  void getNearbyPlaces(String type) async {
    var url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=' +
          latitude.toString() +
          ',' +
          longitude.toString() +
          '&radius=' +
          radius +
          '&type=' +
          type + // Filter by restaurants
          '&key=' +
          apiKey,
    );

    var response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        nearbyPlacesResponse = NearbyPlacesResponse.fromJson(jsonDecode(response.body));
      });
    } else {
      // Handle error
      print('Failed to load nearby places');
    }
  }

  Widget nearbyPlacesWidget(Results results) {
    return InkWell(
      onTap: () async {
        context.read<AutoCompleteBloc>().add(const TextChanged(text: ''));
        context.findAncestorStateOfType<_MapViewState>()?._onPlaceSelected();
        await context.read<MarkerCubit>().selectPlace(results.placeId.toString());
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
                    results.openingHours != null ? "Open" : "Closed",
                    style: TextStyle(
                      color: results.openingHours != null ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            if (results.reference != null) //need to change to link!!!
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
  List<String> _waypoints = [];
  String _originalDestination = '';

  @override
  void initState() {
    super.initState();
    _directionsService = DirectionsService(apiKey: apiKey);
    _getLocation();
  }

  String formatWaypoints(List<String> waypoints) {
    return waypoints.map((wp) => 'via:$wp').join('|');
  }

  void _addPlaceToRoute(Results result) {
    final waypoint = LatLng(result.geometry!.location!.lat!, result.geometry!.location!.lng!);
    final waypointString = '${waypoint.latitude},${waypoint.longitude}';

    setState(() {
      _waypoints.add(waypointString);
    });

    // Call getDirections with the original destination and updated waypoints
    getDirections(_originalDestination, _waypoints);
  }
  void _clearWaypoints() {
    setState(() {
      _waypoints.clear();
    });
  }

  List<Map<String, double>> decodePolyline(String polyline) {
    List<Map<String, double>> points = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
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

        String waypointsParam = waypoints.isNotEmpty ? '&waypoints=${waypoints.join('|')}' : '';
        String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=$destination&key=$apiKey$waypointsParam';

        print('Request URL: $url'); // Log the request URL

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);

          if (data['routes'].isEmpty) {
            print('No routes found');
            return;
          }

          final points = decodePolyline(data['routes'][0]['overview_polyline']['points']);
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

          // Fetch nearby places along the route
          getNearbyMarkers(polylineCoordinates.last);
          getNearbyMarkers(polylineCoordinates[((polylineCoordinates.length - 1) / 2).round()]);

          LatLngBounds bounds = _getBounds(polylineCoordinates);
          context.read<MarkerCubit>().controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 30));
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

  void getNearbyMarkers(LatLng location) async {
    _markers = {};
    var res = await NearbyService.getNearbyPlaces("restaurant", location, 2000);
    if (res != null && res.results != null) {
      for (Results result in res.results!) {
        LatLng loc = LatLng(result.geometry!.location!.lat!, result.geometry!.location!.lng!);
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rating: ${result.rating?.toString() ?? 'N/A'}'),
              const SizedBox(height: 5),
              Text(
                result.openingHours != null && result.openingHours!.openNow != null
                    ? (result.openingHours!.openNow! ? "Status: Open" : "Status: Closed")
                    : "Opening hours: Not available",
                style: TextStyle(
                  color: result.openingHours != null && result.openingHours!.openNow != null
                      ? (result.openingHours!.openNow! ? Colors.green : Colors.red)
                      : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text('Address: ${result.vicinity ?? 'Not available'}'),
              const SizedBox(height: 5),
              if (result.photos != null && result.photos!.isNotEmpty)
                Image.network(
                  'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${result.photos![0].photoReference}&key=$apiKey',
                  fit: BoxFit.cover,
                ),
            ],
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
                _addPlaceToRoute(result);
              },
            ),
          ],
        );
      },
    );
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
        _initialPosition = LatLng(_locationData!.latitude!, _locationData.longitude!);
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
  Widget build(BuildContext context) {
    final markerCubit = context.read<MarkerCubit>();
    CameraPosition kDefaultPosition = const CameraPosition(target: LatLng(11.967375, 121.924812), zoom: 15);
    if (markerCubit.selectedMarker != null) {
      kDefaultPosition = CameraPosition(target: markerCubit.selectedMarker!.position, zoom: 15);
    }

    final kInitialPosition =
        _initialPosition != null ? CameraPosition(target: _initialPosition!, zoom: 15) : kDefaultPosition;

    final textController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Route'),
      ),
      body: _loadingLocation // Check if loading location
          ? Center(child: CircularProgressIndicator()) // Show circular progress indicator while loading
          : Stack(
              children: [
                MapWidget(
                  kInitialPosition: kInitialPosition,
                  polylines: _polyLines,
                  markers: _markers,
                ),
                if (_placeSelected)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: _onFABPressed,
                      child: const Icon(Icons.restaurant),
                    ),
                  ),
                PredictionList(
                  textController: textController,
                  onPlaceSelected: _onPlaceSelected,
                ),
              ],
            ),
    );
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
  final VoidCallback onPlaceSelected;

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
          const SearchResults()
        ],
      ),
    );
  }
}

class SearchResults extends StatelessWidget {
  const SearchResults({
    Key? key,
  }) : super(key: key);

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
                      await context
                          .read<MarkerCubit>()
                          .selectPlace((state as AutoCompleteSuccess).items[index].placeId.toString());
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
