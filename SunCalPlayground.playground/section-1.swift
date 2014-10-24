// Playground - noun: a place where people can play
/*
Source:
Almanac for Computers, 1990
    published by Nautical Almanac Office
United States Naval Observatory
Washington, DC 20392

Inputs:
day, month, year:      date of sunrise/sunset
latitude, longitude:   location for sunrise/sunset
    zenith:                Sun's zenith for sunrise/sunset
        offical      = 90 degrees 50'
civil        = 96 degrees
nautical     = 102 degrees
astronomical = 108 degrees

NOTE: longitude is positive for East and negative for West
    NOTE: the algorithm assumes the use of a calculator with the
trig functions in "degree" (rather than "radian") mode. Most
programming languages assume radian arguments, requiring back
and forth convertions. The factor is 180/pi. So, for instance,
    the equation RA = atan(0.91764 * tan(L)) would be coded as RA
= (180/pi)*atan(0.91764 * tan((pi/180)*L)) to give a degree
answer with a degree input for L.
*/

import UIKit
import Foundation
import CoreLocation

enum SunEvent : Int {
    case SunEventRise = 0
    case SunEventSet
}

func  deg_to_rad(x: Double) -> Double
{
    return (M_PI / 180.0) * x;
}

func  rad_to_deg(x: Double) -> Double
{
    return (180.0 / M_PI) * x;
}

func  deg_sin(x: Double) -> Double
{
    return sin(deg_to_rad(x));
}

func  deg_asin(x: Double) -> Double
{
    return rad_to_deg(asin(x));
}

func  deg_atan(x: Double) -> Double
{
    return rad_to_deg(atan(x));
}

func  deg_tan(x: Double) -> Double
{
    return tan(deg_to_rad(x));
}

func  deg_cos(x: Double) -> Double
{
    return cos(deg_to_rad(x));
}

func  deg_acos(x: Double) -> Double
{
    return rad_to_deg(acos(x));
}

func normalize_range(v: Double, max: Double) -> Double
{
    var variable = v
    while (variable < 0) {
        variable += max;
    }
    
    while (variable >= max) {
        variable -= max;
    }
    
    return variable;
//    var variable : Double = abs(v);
//    let modulous : Double = v % max
//    var variable : Double = abs(modulous)
//    return variable;
}

let inDate = NSDate()

let event = SunEvent.SunEventSet

// calculation of Julian Day Number (http://en.wikipedia.org/wiki/Julian_day ) from Gregorian Date
let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!

let zenith = 90.0

let components = calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitTimeZone , fromDate: inDate)

//    1. first calculate the day of the year
//
let N1 = floor(275.0 * Double(components.month) / 9.0)
let N2 = floor((Double(components.month) + 9.0) / 12.0)
let N3 = (1.0 + floor((Double(components.year) - 4.0 * floor(Double(components.year) / 4.0) + 2.0) / 3.0))
let N = N1 - (N2 * N3) + Double(components.day) - 30.0
//

//let a = (14.0 - Double(components.month)) / 12.0;
//let y : Double = Double(components.year) +  4800.0 - a;
//let m : Double = Double(components.month) + (12.0 * a) - 3.0;
//let N : Double = Double(components.day) + (((153.0 * m) + 2.0) / 5.0) + (365.0 * y) + (y/4.0) - (y/100.0) + (y/400.0) - 32045.0;
//
//println("Julian Date: \(N)\n")
let latitude = 31.20012844
let longitude = 121.46589285

//2. convert the longitude to hour value and calculate an approximate time
//
//lngHour = longitude / 15
//
//if rising time is desired:
//t = N + ((6 - lngHour) / 24)
//if setting time is desired:
//t = N + ((18 - lngHour) / 24)
//

let lngHour : Double = longitude / 15.0

var t : Double
if(event == SunEvent.SunEventRise){
    t = N + ((6.0 - lngHour) / 24.0)
}
else{
    t = N + ((18.0 - lngHour) / 24)
}

//3. calculate the Sun's mean anomaly
//
//M = (0.9856 * t) - 3.289
//

let M = (0.9856 * t) - 3.289


//
//4. calculate the Sun's true longitude
//
//L = M + (1.916 * sin(M)) + (0.020 * sin(2 * M)) + 282.634
//NOTE: L potentially needs to be adjusted into the range [0,360) by adding/subtracting 360
//

var L : Double = M + (1.916 * deg_sin(M)) + (0.020 * deg_sin(2 * M)) + 282.634;
L = normalize_range(L, 360);

//5a. calculate the Sun's right ascension
//
//RA = atan(0.91764 * tan(L))
//NOTE: RA potentially needs to be adjusted into the range [0,360) by adding/subtracting 360
//

var RA : Double = deg_atan(0.91764 * deg_tan(L));
RA = normalize_range(RA, 360);

//5b. right ascension value needs to be in the same quadrant as L
//
let Lquadrant  = (floor( L/90.0)) * 90.0
let RAquadrant = (floor(RA/90.0)) * 90.0
RA = RA + (Lquadrant - RAquadrant)
//
//5c. right ascension value needs to be converted into hours
//
RA = RA / 15.0
//
//6. calculate the Sun's declination
//
//sinDec = 0.39782 * sin(L)
//cosDec = cos(asin(sinDec))

let sinDec = 0.39782 * deg_sin(L);
let cosDec = deg_cos(deg_asin(sinDec));

//
//7a. calculate the Sun's local hour angle
//
//cosH = (cos(zenith) - (sinDec * sin(latitude))) / (cosDec * cos(latitude))
//
let cosH = (deg_cos(zenith) - (sinDec * deg_sin(latitude))) / (cosDec * deg_cos(latitude));


//if (cosH >  1)
//the sun never rises on this location (on the specified date)
//if (cosH < -1)
//the sun never sets on this location (on the specified date)
//

if(cosH > 1.0){
    println("Will not rise in this location!")
}

if(cosH < -1.0){
    println("Will not set in this location!")
}

//SKIPPED!

//7b. finish calculating H and convert into hours
//
//if if rising time is desired:
//H = 360 - acos(cosH)
//if setting time is desired:
//H = acos(cosH)
//
//H = H / 15
//

var H : Double;

if (event == SunEvent.SunEventRise) {
    H = 360.0 - deg_acos(cosH);
} else {
    H = deg_acos(cosH);
}

H = H / 15.0;


//8. calculate local mean time of rising/setting
//
//T = H + RA - (0.06571 * t) - 6.622
//

let T = H + RA - (0.06571 * t) - 6.622;


//9. adjust back to UTC
//
//UT = T - lngHour
//NOTE: UT potentially needs to be adjusted into the range [0,24) by adding/subtracting 24
//
let UT = normalize_range(T - lngHour, 24.0);



//10. convert UT value to local time zone of latitude/longitude
//
//localT = UT + localOffset
let timezone : NSTimeZone = components.timeZone!;
let localSeconds : Double = Double(timezone.secondsFromGMTForDate(inDate))
let localOffset : Double =   localSeconds / 3600.0;
let localT = UT + localOffset

// convert to an NSDate
let hour = trunc(localT);
let hourSeconds = 3600 * (localT - hour);
let minute = hourSeconds / 60;
let second = hourSeconds - (minute * 60);

components.hour = Int(hour)
components.minute = Int( minute)
components.second = Int(second)


let sunset = calendar.dateFromComponents(components)



