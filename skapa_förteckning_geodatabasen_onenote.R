

if (!require("pacman")) install.packages("pacman")
p_load(keyring,
       sf,
       RPostgreSQL,
       mapview,
       RPostgres,
       tidyverse,
       keyring,
       dplyr,
       DBI,
       RPostgres,
       stringr,
       dbplyr,
       writexl)


# ====================Postgis-databasen =======================

source("https://raw.githubusercontent.com/Region-Dalarna/funktioner/main/func_GIS.R", encoding = "utf-8", echo = FALSE)

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

# Hämta lista över alla tabeller
tables <- dbGetQuery(con, "
   SELECT table_schema, table_name
   FROM information_schema.tables
   WHERE table_schema NOT IN ('information_schema', 'pg_catalog')
")

# Skriva ut listan i en tabell för enklare översikt

tables_df <- tables %>%
  arrange(table_schema, table_name)  # Sortera efter schema och tabellnamn

# print(tables_df)

lagers_info <- tables_df %>%
  mutate(
    lagernamn = table_name, # So it can be manually changed
    finns_nu = "Ja",  # Set all rows to "Ja"
    schemalagd = "Nej",  # Set all rows to "Nej"
    
    # Conditionally update 'nedladdning_från' based on schema and table name
    nedladdning_från = case_when(
      table_schema == "topografi_10" ~ "Geotorget",   # If schema is topografi_10
      table_schema == "nvdb" ~ "Lastkajen",           # If schema is nvdb
      table_schema == "byggnader" ~ "Geotorget",      # If schema is byggnader
      table_schema == "karta" & grepl("scb", table_name) ~ "SCB", # If schema is 'karta' and table_name contains 'scb'
      table_schema == "malpunkter" & grepl("laddstationer", table_name) ~ "Nobil" # If schema is 'karta' and table_name contains 'scb'
    )
  ) %>%
  select(
    lagernamn,            # Select the columns in the desired order
    nedladdning_från,
    tabell = table_name,  # Rename 'table_name' to 'tabell'
    schema = table_schema, # Rename 'table_schema' to 'schema'
    finns_nu,
    schemalagd
  )

# # View the updated dataframe
# print(lagers_info)
# 
# getwd()

# Export to Excel with UTF-8 encoding
write_xlsx(lagers_info, "forteckning_geodatabasen.xlsx")


