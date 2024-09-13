if (!require("pacman")) install.packages("pacman")
p_load(keyring,
       sf,
       RPostgreSQL,
       mapview,
       tidyverse,
       dplyr,
       DBI,
       RPostgres,
       stringr,
       dbplyr,
       writexl,
       httr,
       jsonlite)

# getwd()
setwd("G:/skript/gis/geodatabasen/github_geodata")


source("https://raw.githubusercontent.com/Region-Dalarna/funktioner/main/func_GIS.R", encoding = "utf-8", echo = FALSE)

# Retrieve the username and API key from the keyring for the "Nobil" service
nobil_username <- key_list(service = "Nobil")$username
nobil_api_key <- key_get("Nobil", nobil_username)

# Construct the URL using the retrieved username and API key
nobil_url <- paste0(nobil_username, nobil_api_key, "&countrycode=SWE&fromdate=2012-06-02&format=json&file=false")

# Perform the GET request with basic error handling
laddst_sv <- try(GET(nobil_url), silent = TRUE)

if (inherits(laddst_sv, "try-error") || status_code(laddst_sv) != 200) {
  stop("Error fetching data from Nobil API.")
}

# Process the response (assuming you want to convert it to a data frame)
laddst_sv_resp <- fromJSON(content(laddst_sv, as = "text"), flatten = FALSE)


# Extract relevant data and clean it
laddst_sv_df <- laddst_sv_resp$chargerstations$csmd

# Clean 'Position' column (remove parentheses) and split into lat/lon
laddst_sv_df$Position <- gsub("[()]", "", as.character(laddst_sv_df$Position))
laddstolpar <- laddst_sv_df %>%
  separate_wider_delim(Position, ",", names = c("lat", "lon")) # Split into latitude and longitude

# Convert to an sf object (spatial data)
laddstolpar_sf <- st_as_sf(laddstolpar, coords = c("lon", "lat"), crs = 4326, agr = "constant")

laddstolpar_sf <- laddstolpar_sf %>% 
  select(
    namn = name,
    gata = Street,
    gatnr = House_number,
    postnr = Zipcode,
    ort = City,
    kom_kod = Municipality_ID,
    kommun = Municipality,
    lan_kod = County_ID,
    lan = County,
    lages_bskrvng = Description_of_location,
    agare = Owned_by,
    operator = Operator,
    anslutningspunkter = Available_charging_points,
    kommentar = User_comment,
    kontakt = Contact_info,
    skapad = Created,
    uppdaterad = Updated,
    station_status = Station_status,
  )

# Filter the data for Dalarna (länskod = 20)
laddstolpar_sf <- laddstolpar_sf %>% filter(lan_kod == '20')

# # Display the charging stations on a map
# mapview(laddstolpar_sf, zcol = "anslutningspunkter", cex = "anslutningspunkter", legend = TRUE)

# # Check the CRS (should be WGS 84, EPSG: 4326)
# st_crs(laddstolpar_sf)

# Transform to WGS84 (EPSG:4326) if necessary
laddstationer_sf <- st_transform(laddstolpar_sf, 3006)

# Add a column indicating the download date and time
laddstationer_sf <- laddstationer_sf %>%
  mutate(downloaded_at = Sys.time())  # Add current date and time

con <- dbConnect(          # use in other settings
  RPostgres::Postgres(),
  # without the previous and next lines, some functions fail with bigint data 
  #   so change int64 to integer
  bigint = "integer",  
  user = key_list(service = "geodata")$username,
  password = key_get("geodata", key_list(service = "geodata")$username),
  host = "WFALMITVS526.ltdalarna.se",
  port = 5432,
  dbname = "geodata",
  options="-c search_path=public")

st_write(laddstationer_sf, con, "laddstationer_dalarna", delete_layer = TRUE)

# Drop the existing table if it exists in 'malpunkter'
dbExecute(con, "DROP TABLE IF EXISTS malpunkter.\"laddstationer_dalarna\";")

# Move the table to the 'malpunkter' schema
dbExecute(con, "ALTER TABLE public.\"laddstationer_dalarna\" SET SCHEMA malpunkter;")

# Close the database connection
dbDisconnect(con)


# # Check if data is successfully written to the database
# if (dbExistsTable(con, "malpunkter.laddstationer_dalarna")) {
#   message("Table laddstationer_dalarna successfully written to the database.")
  
#   # Optionally, check the number of rows inserted
#   result <- dbGetQuery(con, "SELECT COUNT(*) FROM malpunkter.laddstationer_dalarna")
#   message("Number of rows in laddstationer_dalarna: ", result[[1]])
# } else {
#   stop("Failed to write table to the database.")
# }

# # Check the tables again
# tables <- dbGetQuery(con, "
#    SELECT table_schema, table_name
#    FROM information_schema.tables
#    WHERE table_schema NOT IN ('information_schema', 'pg_catalog')
# ")
# 
# print(tables)
# 

