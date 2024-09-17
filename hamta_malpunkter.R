# Funktion för att skapa tabellöversikt över 'malpunkter' schema
skapa_malpunkter_tabell <- function() {
  
  # Definiera kolumnnamn
  kolumn_namn <- c("namn", "id_kol", "lankol", "kommunkol", "sokord")
  
  # Skapa en tom data.frame med specificerade kolumnnamn
  antal_kol <- length(kolumn_namn)
  malpunkter_df <- as.data.frame(matrix(nrow = 0, ncol = antal_kol)) %>%
    setNames(kolumn_namn) %>%
    mutate(across(1:(antal_kol - 1), as.character),
           sokord = sokord %>% as.list())
  
  # Lägg till rader (tabeller) som ska vara hämtbara
  malpunkter_df <- malpunkter_df %>%  
    add_row(namn = "pipos_data", id_kol = "Serviceplatsid", lankol = "Län", kommunkol = "Kommun", sokord = list(c("pipos", "pipos_data", "komersiell_service", "tillvaxtverket"))) %>%
    add_row(namn = "laddstationer_dalarna", id_kol = "station_status", lankol = "lan_kod", kommunkol = "kom_kod", sokord = list(c("laddstation", "laddstolpe", "laddstationer"))) %>%
    add_row(namn = "resecentrum_dala", id_kol = "id", lankol = "lan", kommunkol = "kommun", sokord = list(c("resecentrum", "resecentrum_dala", "resecentrum_dalarna")))
  
  return(malpunkter_df)
}

# Huvudfunktionen för att hämta data från 'malpunkter' schema
hamta_malpunkter <- function(karttyp, regionkoder = NA) {
  
  # Hämta tabellöversikt
  tabell_df <- skapa_malpunkter_tabell()
  
  # Hitta relevant rad baserat på karttyp (sökord)
  df_rad <- suppressWarnings(str_which(tabell_df$sokord, karttyp))
  
  # Kontrollera om karttypen finns
  if (length(df_rad) == 0) {
    pg_tabell <- "finns ej"
  } else {
    pg_tabell <- tabell_df$namn[df_rad]
  }
  
  # Om karttypen inte finns, visa varning
  if (pg_tabell == "finns ej") {
    warning(paste0("Karttypen ", karttyp, " finns inte i databasen."))
    return(NULL)
  }
  
  # Hantera regionkoder om de är angivna
  kommunkoder <- NULL
  lanskoder <- NULL
  if (all(!is.na(regionkoder)) & all(regionkoder != "00")) {
    kommunkoder <- regionkoder[nchar(regionkoder) == 4]
    lanskoder <- regionkoder[nchar(regionkoder) == 2 & regionkoder != "00"]
  }
  
  # Bygg grundläggande SQL-fråga
  grundquery <- paste0("SELECT * FROM malpunkter.", pg_tabell)
  
  # Modifiera frågan baserat på regionkoder
  if (is.null(kommunkoder) & is.null(lanskoder)) {
    skickad_query <- paste0(grundquery, ";")
  } else {
    skickad_query <- paste0(grundquery, " WHERE ")
    
    # Lägg till länskoder i frågan om de finns
    if (!is.null(lanskoder) & !is.na(tabell_df$lankol[df_rad])) {
      skickad_query <- paste0(skickad_query, tabell_df$lankol[df_rad], " IN (", paste0("'", lanskoder, "'", collapse = ", "), ")")
    }
    
    # Lägg till kommunkoder i frågan om de finns
    if (!is.null(kommunkoder) & !is.na(tabell_df$kommunkol[df_rad])) {
      if (!is.null(lanskoder) & !is.na(tabell_df$lankol[df_rad])) {
        mellanquery <- " OR "
      } else {
        mellanquery <- ""
      }
      skickad_query <- paste0(skickad_query, mellanquery, tabell_df$kommunkol[df_rad], " IN (", paste0("'", kommunkoder, "'", collapse = ", "), ")")
    }
    skickad_query <- paste0(skickad_query, ";")
  }
  
  # Använd inloggningsuppgifter och hämta data från databasen
  retur_sf <- suppressWarnings(las_in_postgis_tabell_till_sf_objekt(
    schema = "malpunkter",
    tabell = pg_tabell,
    skickad_query = skickad_query,
    pg_db_user = key_list(service = "geodata")$username,
    pg_db_pwd = key_get("geodata", key_list(service = "geodata")$username),
    pg_db_host = "WFALMITVS526.ltdalarna.se",
    pg_db_port = 5432,
    pg_db_name_db = "geodata"
  ))
  
  return(retur_sf)
}


# pipos <- hamta_malpunkter("pipos")
# laddstationer <- hamta_malpunkter("laddstationer")
# resecentrum <- hamta_malpunkter("resecentrum")
# 
# mapview(pipos, zcol = "Servicetyp")+
#   mapview(laddstationer, zcol = "anslutningspunkter", cex = "anslutningspunkter")+
#   mapview(resecentrum, zcol ="malpunkt_namn")
