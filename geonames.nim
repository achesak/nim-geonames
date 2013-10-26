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


# Define the types.
type TGeoNamesPostalCode* = tuple[postalCode : string, name : string, countryCode : string, latitude : string, longitude : string,
                                  adminCode1 : string, adminName1 : string, adminCode2 : string, adminName2 : string, adminCode3 : string,
                                  adminName3 : string]

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
