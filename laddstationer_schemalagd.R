# shemaläggning av skript som laddar ner information om laddstationer i Dalarna
# för att det ska funka även när min dator är avstängd behöver skriptet och filsökvägen ligga på servern

# install.packages("taskscheduleR")

library(taskscheduleR)

# Path to your R script

# G:\skript\gis\geodatabasen\schemalaggning
script_path <- "G:/skript/gis/geodatabasen/github_geodata/laddstationer_malpunkter.R"

# Schedule the task to run weekly on Thursday, with a correct start date format
taskscheduler_create(
  taskname = "Update_Laddstationer_Weekly",
  rscript = script_path,
  schedule = "WEEKLY", 
  starttime = "03:00",
  days = c("THU"),
  startdate = format(Sys.Date(), "%Y/%m/%d")  # Explicitly set the start date in the required format
)

# taskscheduler_ls()
# 
# # Hämtar en lista över alla schemalagda uppgifter med specificerade alternativ (i detta fall ingen extra filtrering).
# tasks <- taskscheduler_ls(quote="")
# 
# # Valfritt: Kontrollera den senaste körningstiden och statusen för den specifika uppgiften "Update_Laddstationer_Weekly".
# tasks <- taskscheduler_ls()
# if ("Update_Laddstationer_Weekly" %in% tasks$TaskName) {
#   # Meddelande om den schemalagda uppgiften skapades framgångsrikt.
#   message("Scheduled task created successfully.")
# } else {
#   # Stoppar exekveringen om den schemalagda uppgiften inte hittades.
#   stop("Scheduled task was not created.")
# }
# 
# # Testar att köra ett skript via source för att se om det körs korrekt manuellt.
source("G:/skript/gis/geodatabasen/github_geodata/laddstationer_malpunkter.R")
# 
# # Kör den schemalagda uppgiften direkt (utan att vänta på dess schemalagda tid).
# taskscheduler_runnow("Update_Laddstationer_Weekly")
# 
# # Laddar loggfilen för uppgiften för att läsa och visa de senaste 20 raderna.
# log_file_path <- "G:/skript/gis/geodatabasen/schemalaggning/laddstationer_malpunkter.log"
# log_content <- readLines(log_file_path)
# tail(log_content, n = 20)  # Visar de sista 20 raderna från loggen
