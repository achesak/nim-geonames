# GeoNames API wrapper

# Written by Adam Chesak.
# Code released under the MIT open source license.

# Import modules.
import httpclient
import strutils
import xmlparser
import xmltree
import streams
import cgi
import math


# Define the types.
type TGeoNamesBBox* = tuple[west : string, north : string, east : string, south : string]

type TGeoNamesName* = tuple[toponymName : string, name : string, latitude : string, longitude : string, geonameID : string, countryCode : string,
                            countryName : string, fcl : string, fcode : string, fclName : string, fcodeName : string, population : string,
                            elevation : string, continentCode : string, adminCode1 : string, adminName1 : string, adminCode2 : string,
                            adminName2 : string, adminCode3 : string, adminName3 : string, dstOffset : string, gmtOffset : string, timezone : string,
                            distance : string, alternateNames : string, bbox : TGeoNamesBBox]

type TGeoNamesAddress* = tuple[street : string, mtfcc : string, streetNumber : string, latitude : string, longitude : string, distance : string,
                               postalCode : string, placeName : string, countryCode : string, adminCode1 : string, adminName1 : string, 
                               adminCode2 : string, adminName2 : string, adminCode3 : string, adminName3 : string]
                            
type TGeoNamesExtendedName* = tuple[nameType : string, address : TGeoNamesAddress, geonames : seq[TGeoNamesName], ocean : string]

type TGeoNamesCountry* = tuple[countryCode : string, countryName : string, numPostalCodes : int, minPostalCode : string, maxPostalCode : string]

type TGeoNamesPostalCode* = tuple[postalCode : string, name : string, countryCode : string, latitude : string, longitude : string,
                                  adminCode1 : string, adminName1 : string, adminCode2 : string, adminName2 : string, adminCode3 : string,
                                  adminName3 : string, distance : string]

type TGeoNamesPostalCodes* = tuple[totalResults : int, codes : seq[TGeoNamesPostalCode]]


proc postalCodeSearch*(username : string, postalCode : string = "", postalCodeStartsWith : string = "", placeName : string = "", placeNameStartsWith : string = "",
                       country : string = "",  countryBias : string = "", maxRows : int = 10, style : string = "MEDIUM", operator : string = "AND", 
                       charset : string = "UTF8", isReduced : bool = false, east : float = 0.0, west : float = 0.0, north : float = 0.0,
                       south : float = 0.0): TGeoNamesPostalCodes = 
    ## Returns a list of postal codes and places for the placeName/postalCode specified.
    
    # Build the URL.
    var url : string = "http://api.geonames.org/postalCodeSearch?"
    if postalCode != "":
        url = url & "postalcode=" & postalCode & "&"
    elif postalCodeStartsWith != "":
        url = url & "postalcode_startsWith=" & postalCodeStartsWith & "&"
    elif placeName != "":
        url = url & "placename=" & urlEncode(placeName) & "&"
    elif placeNameStartsWith != "":
        url = url & "placename_startsWith=" & urlEncode(placeNameStartsWith) & "&"
    if country != "":
        url = url & "country=" & country & "&"
    if countryBias != "":
        url = url & "countryBias=" & country & "&"
    if east != 0.0:
        url = url & "east=" & formatFloat(east) & "&"
    if west != 0.0:
        url = url & "west=" & formatFloat(west) & "&"
    if north != 0.0:
        url = url & "north=" & formatFloat(north) & "&"
    if south != 0.0:
        url = url & "south=" & formatFloat(south) & "&"
    if isReduced == true:
        url = url & "isReduced=true&"
    else:
        url = url & "isReduced=false&"
    url = url & "maxRows=" & intToStr(maxRows) & "&"
    url = url & "style=" & style & "&"
    url = url & "operator=" & operator & "&"
    url = url & "charset=" & charset & "&"
    url = url & "username=" & username
    
    # Get the data.
    var response : string = getContent(url)
    
    # Parse the XML.
    var xml : PXmlNode = parseXML(newStringStream(response))
    
    # Create the return object.
    var codes : TGeoNamesPostalCodes
    
    # Populate the return object.
    codes.totalResults = parseInt(xml.child("totalResultsCount").innerText)
    
    # Only add the codes if there are any.
    if codes.totalResults != 0:
        
        # Loop through the codes and add the info.
        var postCodesXML = xml.findAll("code")
        var postCodes = newSeq[TGeoNamesPostalCode](len(postCodesXML))
        for i in 0..high(postCodesXML):
            
            var code : TGeoNamesPostalCode
            code.postalCode = postCodesXML[i].child("postalcode").innerText
            code.name = postCodesXML[i].child("name").innerText
            code.countryCode = postCodesXML[i].child("countryCode").innerText
            code.latitude = postCodesXML[i].child("lat").innerText
            code.longitude = postCodesXML[i].child("lng").innerText
            if style != "SHORT":
                code.adminCode1 = postCodesXML[i].child("adminCode1").innerText
                code.adminName1 = postCodesXML[i].child("adminName1").innerText
                code.adminCode2 = postCodesXML[i].child("adminCode2").innerText
                code.adminName2 = postCodesXML[i].child("adminName2").innerText
                code.adminCode3 = postCodesXML[i].child("adminCode3").innerText
                code.adminName3 = postCodesXML[i].child("adminName3").innerText
            
            postCodes[i] = code
        
        # Add the codes to the return object.
        codes.codes = postCodes
        
    # Return the postal codes.
    return codes


proc findNearbyPostalCodes*(username : string, latitude : float = NaN, longitude : float = NaN, postalCode : string = "", country : string = "",
                            localCountry : bool = false, maxRows : int = 5, radius : float = 0.0, style : string = "MEDIUM"): TGeoNamesPostalCodes = 
    ## Returns a list of postal codes and places for the latitude/longitude specified. The result is sorted by distance.
    
    # Build the URL.
    var url : string = "http://api.geonames.org/findNearbyPostalCodes?"
    if math.classify(latitude) != fcNaN:
        url = url & "lat=" & formatFloat(latitude) & "&lng=" & formatFloat(longitude) & "&"
    else:
        url = url & "postalcode=" & postalCode & "&"
    if country != "":
        url = url & "country=" & country & "&"
    if localCountry == true:
        url = url & "localCountry=true&"
    else:
        url = url & "localCountry=false&"
    if radius != 0.0:
        url = url & "radius=" & formatFloat(radius) & "&"
    url = url & "style=" & style & "&"
    url = url & "maxRows=" & intToStr(maxRows) & "&"
    url = url & "username=" & username
   
    # Get the data.
    var response : string = getContent(url)
    
    # Parse the XML.
    var xml : PXmlNode = parseXML(newStringStream(response))
    
    # Create the return object.
    var codes : TGeoNamesPostalCodes
    codes.totalResults = 0
    
    # Only add the codes if there are any.
    if xml.child("code") != nil:
        
        # Loop through the codes and add the info.
        var postCodesXML = xml.findAll("code")
        codes.totalResults = len(postCodesXML)
        var postCodes = newSeq[TGeoNamesPostalCode](len(postCodesXML))
        for i in 0..high(postCodesXML):
            
            var code : TGeoNamesPostalCode
            code.postalCode = postCodesXML[i].child("postalcode").innerText
            code.name = postCodesXML[i].child("name").innerText
            code.countryCode = postCodesXML[i].child("countryCode").innerText
            code.latitude = postCodesXML[i].child("lat").innerText
            code.longitude = postCodesXML[i].child("lng").innerText
            code.distance = postCodesXML[i].child("distance").innerText
            if style != "SHORT":
                code.adminCode1 = postCodesXML[i].child("adminCode1").innerText
                code.adminName1 = postCodesXML[i].child("adminName1").innerText
                code.adminCode2 = postCodesXML[i].child("adminCode2").innerText
                code.adminName2 = postCodesXML[i].child("adminName2").innerText
                code.adminCode3 = postCodesXML[i].child("adminCode3").innerText
                code.adminName3 = postCodesXML[i].child("adminName3").innerText
            
            postCodes[i] = code
        
        # Add the codes to the return object.
        codes.codes = postCodes
    
    # Return the postal codes.
    return codes


proc postalCodeCountryInfo*(username : string): seq[TGeoNamesCountry] = 
    ## Returns the countries for which postal code geocoding is available.
    
    # Get the data.
    var response : string = getContent("http://api.geonames.org/postalCodeCountryInfo?username=" & username)
    
    # Parse the XML.
    var xml : PXmlNode = parseXML(newStringStream(response))
    
    # Create the return object.
    var countryXML : seq[PXmlNode] = xml.findAll("country")
    var countries = newSeq[TGeoNamesCountry](len(countryXML))
    
    # Loop through the countries and add them to the object.
    for i in 0..high(countryXML):
        
        var country : TGeoNamesCountry
        country.countryCode = countryXML[i].child("countryCode").innerText
        country.countryName = countryXML[i].child("countryName").innerText
        country.numPostalCodes = parseInt(countryXML[i].child("numPostalCodes").innerText)
        country.minPostalCode = countryXML[i].child("minPostalCode").innerText
        country.maxPostalCode = countryXML[i].child("maxPostalCode").innerText
        
        countries[i] = country
    
    # Return the country info.
    return countries


proc findNearbyPlaceName*(username : string, latitude : float, longitude : float, language : string = "", radius : float = 0.0,
                          maxRows : int = 10, localCountry : bool = true, cities : string = "", style : string = "MEDIUM"): seq[TGeoNamesName] = 
    ## Returns the closest populated places for the latitude/longitude specified.
    
    # Build the URL.
    var url : string = "http://api.geonames.org/findNearbyPlaceName?"
    url = url & "lat=" & formatFloat(latitude) & "&"
    url = url & "lng=" & formatFloat(longitude) & "&"
    if language != "":
        url = url & "lang=" & language & "&"
    if radius != 0.0:
        url = url & "radius=" & formatFloat(radius) & "&"
    if cities != "":
        url = url & "cities=" & cities & "&"
    if localCountry == true:
        url = url & "localCountry=true&"
    else:
        url = url & "localCountry=false&"
    url = url & "maxRows=" & intToStr(maxRows) & "&"
    url = url & "style=" & style & "&"
    url = url & "username=" & username
    
    # Get the data.
    var response : string = getContent(url)
    
    # Parse the XML.
    var xml : PXmlNode = parseXML(newStringStream(response))
    
    # Create the return object.
    var locations : seq[PXmlNode] = xml.findAll("geoname")
    var names = newSeq[TGeoNamesName](len(locations))
    
    # Loop through the location and add them to the object.
    for i in 0..high(locations):
        
        var location : TGeoNamesName
        location.toponymName = locations[i].child("toponymName").innerText
        location.name = locations[i].child("name").innerText
        location.latitude = locations[i].child("lat").innerText
        location.longitude = locations[i].child("lng").innerText
        location.geonameID = locations[i].child("geonameId").innerText
        location.countryCode = locations[i].child("countryCode").innerText
        location.fcl = locations[i].child("fcl").innerText
        location.fcode = locations[i].child("fcode").innerText
        location.distance = locations[i].child("distance").innerText
        if style == "MEDIUM" or style == "LONG" or style == "FULL":
            location.countryName = locations[i].child("countryName").innerText
        if style == "LONG" or style == "FULL":
            location.fclName = locations[i].child("fclName").innerText
            location.fcodeName = locations[i].child("fcodeName").innerText
            location.population = locations[i].child("population").innerText
        if style == "FULL":
            location.elevation = locations[i].child("elevation").innerText
            location.continentCode = locations[i].child("continentCode").innerText
            location.alternateNames = locations[i].child("alternateNames").innerText
            if locations[i].child("adminCode1") != nil:
                location.adminCode1 = locations[i].child("adminCode1").innerText
                location.adminName1 = locations[i].child("adminName1").innerText
            if locations[i].child("adminCode2") != nil:
                location.adminCode2 = locations[i].child("adminCode2").innerText
                location.adminName2 = locations[i].child("adminName2").innerText
            if locations[i].child("adminCode3") != nil:
                location.adminCode3 = locations[i].child("adminCode3").innerText
                location.adminName3 = locations[i].child("adminName3").innerText
            location.dstOffset = locations[i].child("timezone").attr("dstOffset")
            location.gmtOffset = locations[i].child("timezone").attr("gmtOffset")
            location.timezone = locations[i].child("timezone").innerText
        
        names[i] = location
    
    # Return the locations.
    return names


proc findNearby*(username : string, latitude : float, longitude : float,  radius : float = 0.0, featureClass : string = "",
                 featureCode : string = "", maxRows : int = 10, localCountry : bool = true, style : string = "MEDIUM"): seq[TGeoNamesName] = 
    ## Returns the closest toponym for the latitude/longitude specified.
    
    # Build the URL.
    var url : string = "http://api.geonames.org/findNearby?"
    url = url & "lat=" & formatFloat(latitude) & "&"
    url = url & "lng=" & formatFloat(longitude) & "&"
    if radius != 0.0:
        url = url & "radius=" & formatFloat(radius) & "&"
    if featureClass != "":
        url = url & "featureClass=" & featureClass & "&"
    if featureCode != "":
        url = url & "featureCode=" & featureCode & "&"
    if localCountry == true:
        url = url & "localCountry=true&"
    else:
        url = url & "localCountry=false&"
    url = url & "maxRows=" & intToStr(maxRows) & "&"
    url = url & "style=" & style & "&"
    url = url & "username=" & username
    
    # Get the data.
    var response : string = getContent(url)
    
    # Parse the XML.
    var xml : PXmlNode = parseXML(newStringStream(response))
    
    # Create the return object.
    var locations : seq[PXmlNode] = xml.findAll("geoname")
    var names = newSeq[TGeoNamesName](len(locations))
    
    # Loop through the location and add them to the object.
    for i in 0..high(locations):
        
        var location : TGeoNamesName
        location.toponymName = locations[i].child("toponymName").innerText
        location.name = locations[i].child("name").innerText
        location.latitude = locations[i].child("lat").innerText
        location.longitude = locations[i].child("lng").innerText
        location.geonameID = locations[i].child("geonameId").innerText
        location.countryCode = locations[i].child("countryCode").innerText
        location.fcl = locations[i].child("fcl").innerText
        location.fcode = locations[i].child("fcode").innerText
        location.distance = locations[i].child("distance").innerText
        if style == "MEDIUM" or style == "LONG" or style == "FULL":
            location.countryName = locations[i].child("countryName").innerText
        if style == "LONG" or style == "FULL":
            location.fclName = locations[i].child("fclName").innerText
            location.fcodeName = locations[i].child("fcodeName").innerText
            location.population = locations[i].child("population").innerText
        if style == "FULL":
            location.elevation = locations[i].child("elevation").innerText
            location.continentCode = locations[i].child("continentCode").innerText
            location.alternateNames = locations[i].child("alternateNames").innerText
            if locations[i].child("adminCode1") != nil:
                location.adminCode1 = locations[i].child("adminCode1").innerText
                location.adminName1 = locations[i].child("adminName1").innerText
            if locations[i].child("adminCode2") != nil:
                location.adminCode2 = locations[i].child("adminCode2").innerText
                location.adminName2 = locations[i].child("adminName2").innerText
            if locations[i].child("adminCode3") != nil:
                location.adminCode3 = locations[i].child("adminCode3").innerText
                location.adminName3 = locations[i].child("adminName3").innerText
            location.dstOffset = locations[i].child("timezone").attr("dstOffset")
            location.gmtOffset = locations[i].child("timezone").attr("gmtOffset")
            location.timezone = locations[i].child("timezone").innerText
        
        names[i] = location
    
    # Return the locations.
    return names


proc extendedFindNearby*(username : string, latitude : float, longitude : float, style : string = "MEDIUM"): TGeoNamesExtendedName = 
    ## Returns the most detailed information available for he latitude/longitude specified. In the US it returns the address information,
    ## in other countries it returns the heirarchy service, and for oceans it returns the ocean name.
    
    # Build the URL.
    var url : string = "http://api.geonames.org/extendedFindNearby?"
    url = url & "lat=" & formatFloat(latitude) & "&"
    url = url & "lng=" & formatFloat(longitude) & "&"
    url = url & "style=" & style & "&"
    url = url & "username=" & username
    
    # Get the data.
    var response : string = getContent(url)
    
    # Parse the XML.
    var xml : PXmlNode = parseXML(newStringStream(response))
    
    # Create the return object.
    var name : TGeoNamesExtendedName
    
    # If the place is an ocean:
    if xml.child("ocean") != nil:
        
        name.nameType = "ocean"
        name.ocean = xml.child("ocean").child("name").innerText
    
    # If the place is in the US:
    if xml.child("address") != nil:
        
        name.nameType = "address"
        var ad : PXmlNode = xml.child("address")
        var a : TGeoNamesAddress
        a.street = ad.child("street").innerText
        a.mtfcc = ad.child("mtfcc").innerText
        a.streetNumber = ad.child("streetNumber").innerText
        a.latitude = ad.child("lat").innerText
        a.longitude = ad.child("lng").innerText
        a.distance = ad.child("distance").innerText
        a.postalCode = ad.child("postalcode").innerText
        a.placeName = ad.child("placename").innerText
        a.countryCode = ad.child("countryCode").innerText
        if ad.child("adminCode1") != nil:
            a.adminCode1 = ad.child("adminCode1").innerText
            a.adminName1 = ad.child("adminName1").innerText
        if ad.child("adminCode2") != nil:
            a.adminCode2 = ad.child("adminCode2").innerText
            a.adminName2 = ad.child("adminName2").innerText
        if ad.child("adminCode3") != nil:
            a.adminCode3 = ad.child("adminCode3").innerText
            a.adminName3 = ad.child("adminName3").innerText
        
        name.address = a
    
    # If the place is outside the US:
    if xml.child("geoname") != nil:
        
        name.nameType = "geoname"
        
        # Create the return object.
        var g : seq[PXmlNode] = xml.findAll("geoname")
        var names = newSeq[TGeoNamesName](len(g))
        
        # Loop through the names and add them to the object.
        for i in 0..high(g):
            
            var n : TGeoNamesName
            n.toponymName = g[i].child("toponymName").innerText
            n.name = g[i].child("name").innerText
            n.latitude = g[i].child("lat").innerText
            n.longitude = g[i].child("lng").innerText
            n.geonameID = g[i].child("geonameId").innerText
            n.countryCode = g[i].child("countryCode").innerText
            n.fcl = g[i].child("fcl").innerText
            n.fcode = g[i].child("fcode").innerText
            if style == "MEDIUM" or style == "LONG" or style == "FULL":
                n.countryName = g[i].child("countryName").innerText
            if style == "LONG" or style == "FULL":
                n.fclName = g[i].child("fclName").innerText
                n.fcodeName = g[i].child("fcodeName").innerText
                n.population = g[i].child("population").innerText
            if style == "FULL":
                if g[i].child("elevation") != nil:
                    n.elevation = g[i].child("elevation").innerText
                if g[i].child("continentCode") != nil:
                    n.continentCode = g[i].child("continentCode").innerText
                n.alternateNames = g[i].child("alternateNames").innerText
                if g[i].child("adminCode1") != nil:
                    n.adminCode1 = g[i].child("adminCode1").innerText
                    n.adminName1 = g[i].child("adminName1").innerText
                if g[i].child("adminCode2") != nil:
                    n.adminCode2 = g[i].child("adminCode2").innerText
                    n.adminName2 = g[i].child("adminName2").innerText
                if g[i].child("adminCode3") != nil:
                    n.adminCode3 = g[i].child("adminCode3").innerText
                    n.adminName3 = g[i].child("adminName3").innerText
                if g[i].child("timezone") != nil:
                    n.dstOffset = g[i].child("timezone").attr("dstOffset")
                    n.gmtOffset = g[i].child("timezone").attr("gmtOffset")
                    n.timezone = g[i].child("timezone").innerText
                if g[i].child("bbox") != nil:
                    var b : TGeoNamesBBox
                    b.west = g[i].child("bbox").child("west").innerText
                    b.north = g[i].child("bbox").child("north").innerText
                    b.east = g[i].child("bbox").child("east").innerText
                    b.south = g[i].child("bbox").child("south").innerText
                    n.bbox = b
            
            names[i] = n
        
        # Add the names to the return object.
        name.geonames = names
    
    # Return the information.
    return name
