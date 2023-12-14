import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:weather/model/Location.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final api_key = "6a58e10ed6e9f90ebb7148bf5b2ff687";

  // State Variables
  String searchParam = '';
  dynamic city = "Chennai";
  dynamic temp = "22";
  dynamic description = "Clear Sky";
  dynamic imageUrl = "https://openweathermap.org/img/wn/10d@2x.png";
  dynamic humidity = 62;
  dynamic windspeed = 0.62;
  List<LocationModel> locationList = <LocationModel>[];
  Timer? debounce;

  //State Variables for UI
  bool isSearching = false;
  bool isLoading = true;

  //Function for getting the weather details from the selected location
  Future<void> getWeatherDetails(double lat, double lon, String name) async {
    final getWeatherEndpoint =
        "https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${api_key}&units=metric";
    setState(() {
      isLoading = true;
    });
    final response = await http.get(Uri.parse(getWeatherEndpoint));
    final respBody = await jsonDecode(response.body);
    print(respBody);
    _controller.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      city = name;
      temp = respBody['main']['temp'].toString();
      description = respBody['weather'][0]['description'];
      imageUrl =
          "https://openweathermap.org/img/wn/${respBody['weather'][0]['icon']}@2x.png";
      humidity = respBody['main']['humidity'].toString();
      windspeed = respBody['wind']['speed'].toString();
      isSearching = false;
      isLoading = false;
    });
  }

  // Function for getting the search results
  Future<void> getSearchResults(String val) async {
    if (val.isEmpty) {
      return;
    }

    final geoCodingEndpoint =
        "http://api.openweathermap.org/geo/1.0/direct?q=$val&appid=$api_key&limit=10";
    setState(() {
      isLoading = true;
    });
    final response = await http.get(Uri.parse(geoCodingEndpoint));
    final respBody = await jsonDecode(response.body);

    List<LocationModel> listlocation = <LocationModel>[];

    respBody.forEach((ele) {
      listlocation.add(LocationModel(
        name: ele['name'],
        lat: ele['lat'],
        lon: ele['lon'],
        Country: ele['country'],
        state: ele['state'],
      ));
    });
    print(listlocation.length);

    if (mounted) {
      setState(() {
        locationList = listlocation;
        isLoading = false;
      });
    }
  }

  //To show case some mock weather details
  @override
  void initState() {
    getWeatherDetails(51.5073219, -0.1276474, "London");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 50.h),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bgi.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              TextField(
                onChanged: (val) {
                  if (debounce?.isActive ?? false) debounce?.cancel();
                  debounce = Timer(const Duration(milliseconds: 500), () async {
                    await getSearchResults(val);
                    if (mounted) {
                      setState(() {
                        searchParam = val;
                        isSearching = true;
                      });
                    }
                  });
                },
                onSubmitted: (_) {
                  setState(() {
                    searchParam = _;
                    isSearching = false;
                  });
                },
                controller: _controller,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(2.h),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.25),
                  hintText: "Search City",
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                ),
              ),
              isLoading
                  ? Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : isSearching
                      ? ListView.builder(
                          shrinkWrap: true,
                          itemCount: locationList.length,
                          itemBuilder: (BuildContext context, int index) {
                            LocationModel location = locationList[index];
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                  color: Colors.white38,
                                  borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                onTap: () async {
                                  print(location.lat);
                                  await getWeatherDetails(location.lat,
                                      location.lon, location.name);
                                },
                                title: Text(
                                  location.name,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  "${location.state},${location.Country}",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Column(
                          children: [
                            SizedBox(
                              height: 28.h,
                            ),
                            Container(
                              constraints: BoxConstraints(minHeight: 200.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(25.r),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        city,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 40.h,
                                      ),
                                      Text(
                                        "$temp°C",
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 36.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 8.h,
                                      ),
                                      Text(
                                        description,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Image(
                                    image: NetworkImage(imageUrl),
                                    height: 150.h,
                                    fit: BoxFit.contain,
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 40.h,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 150.h,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(25.r),
                                    ),
                                    padding: EdgeInsets.all(14.h),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Image.asset(
                                              "assets/images/humidity.png",
                                              height: 25.h,
                                              fit: BoxFit.contain,
                                            ),
                                            SizedBox(
                                              width: 10.w,
                                            ),
                                            Text(
                                              "Humidity",
                                              style: GoogleFonts.inter(
                                                color: Colors.white
                                                    .withOpacity(0.75),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14.sp,
                                              ),
                                            )
                                          ],
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              "$humidity%",
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 36.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 20.w,
                                ),
                                Expanded(
                                  child: Container(
                                    height: 150.h,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(25.r),
                                    ),
                                    padding: EdgeInsets.all(14.h),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Image.asset(
                                              "assets/images/humidity.png",
                                              height: 25.h,
                                              fit: BoxFit.contain,
                                            ),
                                            SizedBox(
                                              width: 10.w,
                                            ),
                                            Text(
                                              "Wind Speed",
                                              style: GoogleFonts.inter(
                                                color: Colors.white
                                                    .withOpacity(0.75),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14.sp,
                                              ),
                                            )
                                          ],
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "$windspeed",
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 36.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  "m/s",
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 15.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
            ],
          ),
        ),
      ),
    );
  }
}
