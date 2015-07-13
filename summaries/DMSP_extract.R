# Data Extraction from raw DMSP-OLS orbital files
#
# Brian Min, Priyamvada Trivedi
# University of Michigan
# This version: 25 February 2015

print(paste("wd=", getwd(), sep=""))

#Get the input and output directory names from the extra arguments
args <- commandArgs(trailingOnly = FALSE)
args
length(args)
if (length(args) != 8) stop("Usage: r --slave --no-restore --file=DMSP_extract.R --args /absolute/path/to/village-points.shp input-dir output-dir");
india_village_points <- args[length(args)-2]
inputDirectory = args[length(args)-1]
outputDirectory = args[length(args)]

#Set the working directory ot location where the images are stored
setwd(inputDirectory)
print(paste("wd=", getwd(), sep=""))


# dependencies

library(raster)
library(rgdal)
library(maptools)
library(reshape)
library(foreign)
library(sp)

#Retrieve the village coordinates
shape = readShapePoints(india_village_points) # Reading in the file that contains the village coordinates

villXYcoords = data.frame(shape$LONGITUDE, shape$LATITUDE) #XY coordinates
villagecode = data.frame(shape$C_CODE01) #to get the village code
acid = data.frame(shape$AC_ID)

#Get the input files
#files = list.files(pattern = ".vis.tif$") #for getting the visible mask

#GET ALL THE FILES
files = list.files(pattern = ".tif$")

#initializing values
l_obs = substr(files[1],1,15)
rasters = numeric(0)
cm = ""
li = ""
tir = ""
vis = ""
sam = ""
slm = ""

#Process the input files
first = TRUE

#Processing starts
for (i in 1:length(files)){
  obs = substr(files[i],1,15)
  
  if (obs == l_obs) {
    print(files[i])
    print(i)
    satellite = substr(files[i],1,7)
    month = substr(files[i],8,9)
    day = substr(files[i],10,11)
    timestamp = substr(files[i],12,15)
    filetype = substr(files[i],24,26)
    print(filetype)
    
    rasters = raster(files[i], layer = 1, values = TRUE) 
    rasValue = extract(rasters, villXYcoords) # Extracting raster values
    print(summary(rasValue))
    
    if (filetype == "cm.") {
      cm = rasValue
    } else if (filetype == "li.") {
      li = rasValue
    } else if (filetype == "tir") {
      tir = rasValue
    } else if (filetype == "vis") {
      vis = rasValue
    } else if (filetype == "sam") {
      sam = rasValue 
    } else if (filetype == "slm") {
      slm = rasValue
    }
    
  } else {
    combinePointValues = cbind(acid, villagecode, villXYcoords, satellite, month, day, timestamp, cm, li, tir, vis, sam, slm)
    #dat = combinePointValues
    dat = subset(combinePointValues, combinePointValues$vis!=255)
    dir = substring(outputDirectory, 34)
    filename = paste(dir, "013015-Hardoi.csv", sep="")

    write.table(dat, file = paste(outputDirectory, filename, sep="/"), append = TRUE, sep = ",", row.names = FALSE, col.names = first)
    first = FALSE
    
    #resetting all values
    rasters = numeric(0)
    cm = ""
    li = ""
    tir = ""
    vis = ""
    sam = ""
    slm = ""
    l_obs = obs
    
    print(files[i])
    print(i)
    satellite = substr(files[i],1,7)
    month = substr(files[i],8,9)
    day = substr(files[i],10,11)
    timestamp = substr(files[i],12,15)
    filetype = substr(files[i],24,26)
    print(filetype)
    
    rasters = raster(files[i], layer = 1, values = TRUE) 
    rasValue = extract(rasters, villXYcoords) # Extracting raster values
    print(summary(rasValue))
    
    if (filetype == "cm.") {
      cm = rasValue
    } else if (filetype == "li.") {
      li = rasValue
    } else if (filetype == "tir") {
      tir = rasValue
    } else if (filetype == "vis") {
      vis = rasValue
    } else if (filetype == "sam") {
      sam = rasValue
    } else if (filetype == "slm") {
      slm = rasValue
    }
  }
}
combinePointValues = cbind(acid, villagecode, villXYcoords, satellite, month, day, timestamp, cm, li, tir, vis, sam, slm)
#dat = combinePointValues
dat = subset(combinePointValues, combinePointValues$vis!=255)
dir = substring(outputDirectory, 34)
filename = paste(dir, "output.csv", sep="")

write.table(dat, file = paste(outputDirectory, filename, sep="/"), append = TRUE, sep = ",", row.names = FALSE, col.names = first)
first = FALSE

# END

