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
type TGeoNamesPostalCode* = tuple[postalCode : string, name : string, latitude : string, longitude : string, adminCode1 : string,
                                  adminName1 : string, adminCode2 : string, adminName2 : string, adminCode3 : string,
                                  adminName3 : string]

type TGeoNamesPostalCodes* = tuple[totalResults : int, codes : seq[TGeoNamesPostalCode]]


proc postalCodeSearch*(postalCode : string = "", postalCodeStartsWith : string = "", placeName : string = "", country : string = "", 
                       countryBias : string = "", maxRows : int = 10, style : string = "MEDIUM", operator : string = "AND", 
                       charset : string = "UTF8", isReduced : bool = false, east : float = 0.0, west : float = 0.0, north : float = 0.0,
                       south : float = 0.0): TGeoNamesPostalCodes = 
    ## Returns a list of postal codes and places for the placeName/postalCode specified.
