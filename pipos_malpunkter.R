
# hämtar data manuellt från https://serviceanalys.tillvaxtverket.se/sa2/statistics

# sparar i G:\skript\gis\geodatabasen\data_manuell_hamtning

# filen heter service20240912-154425.csv

# Skriptet lägger till data i geodatabasen

# Load necessary libraries
if (!require("pacman")) install.packages("pacman")
p_load(keyring, sf, RPostgreSQL, mapview, tidyverse, dplyr, DBI, RPostgres, stringr, dbplyr, writexl, httr, jsonlite)

# # Set working directory
# setwd("G:/skript/gis/geodatabasen/schemalaggning")

# # Source additional functions from GitHub
# source("https://raw.githubusercontent.com/Region-Dalarna/funktioner/main/func_GIS.R", encoding = "utf-8", echo = FALSE)

# Use read_delim() instead of read_csv() when specifying a custom delimiter
pipos <- read_delim(pipos_filsokvag, locale = locale(encoding = "Windows-1252"), delim = ";")

pipos_sf <- pipos %>%
  st_as_sf(coords = c("X", "Y"), crs = 3006, remove = FALSE)  # Replace 3006 with the correct CRS if it's different

# mapview(pipos_sf)

# Add a timestamp for when the data was imported to the database
pipos_sf <- pipos_sf %>%
  mutate(imported_at = Sys.time())

# Connect to the PostgreSQL/PostGIS database
con <- dbConnect(
  RPostgres::Postgres(),
  bigint = "integer",  
  user = key_list(service = "geodata")$username,
  password = key_get("geodata", key_list(service = "geodata")$username),
  host = "WFALMITVS526.ltdalarna.se",
  port = 5432,
  dbname = "geodata",
  options = "-c search_path=public"
)

# Write the data to a new table in the PostGIS database
# You can set delete_layer = TRUE to overwrite if needed
st_write(pipos_sf, con, "pipos_data", delete_layer = TRUE, append = FALSE)

# Move the table to the correct schema (if needed)
dbExecute(con, "ALTER TABLE public.\"pipos_data\" SET SCHEMA malpunkter;")

# Confirm the data was written successfully by checking the row count in the database
result <- dbGetQuery(con, 'SELECT COUNT(*) FROM malpunkter."pipos_data"')
print(result)

# Disconnect from the database
dbDisconnect(con)

