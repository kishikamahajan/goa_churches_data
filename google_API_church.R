library(tidyverse)
library(tidygeocoder)
library(sf)
library(tmap)
library(ggmap)

# Reading the data
churches <- readr::read_csv("/Users/kishikamahajan/Desktop/church_data_updated.csv")

# Registering Google API
register_google(key = "---")

# Getting the lats and longs for addresses
churches_with_addresses <- churches %>%
  mutate(geocode_result = if_else(cleaned_address != "Not found",
                                  map(updated_address, ~geocode(.x)),  # Apply geocode if valid address
                                  list(NULL)),   # No geocoding for "Not found"
         lat = map_dbl(geocode_result, ~if (!is.null(.x)) .x$lat else NA_real_),  # Extract lat or return NA
         lon = map_dbl(geocode_result, ~if (!is.null(.x)) .x$lon else NA_real_))  # Extract lon or return NA

churches_with_addresses_sf <- st_as_sf(churches_with_addresses, 
                                       coords = c("lon", "lat"), 
                                       crs = 4326, 
                                       na.fail = FALSE) 

# PLotting the points
tmap_mode("view")
tm_shape(churches_with_addresses_sf) + tm_dots()

# Adding the built dates for missing churches
churches_with_addresses_sf$built_date[churches_with_addresses_sf$church_name == "Our Lady of the Rosary Church, Curca, Goa"] <- 1984
churches_with_addresses_sf$built_date[churches_with_addresses_sf$church_name == "Our Lady of Refuge Church, Mandur, Goa"] <- 1710
churches_with_addresses_sf$built_date[churches_with_addresses_sf$church_name == "St Thomas Church, Old Goa"] <- 1596
churches_with_addresses_sf$built_date[churches_with_addresses_sf$church_name == "St. Mathias the Apostle Church, Malar, Goa"] <- "between 1590 and 1597"
churches_with_addresses_sf$built_date[churches_with_addresses_sf$church_name == "Our Lady, Mother of God Church, Saligao, Goa"] <- 1867
churches_with_addresses_sf$built_date[churches_with_addresses_sf$church_name == "Our Lady of the Rosary Church, Sadolxem, Goa"] <- "between 1544 and 1547"
churches_with_addresses_sf$built_date[churches_with_addresses_sf$church_name == "Our Lady of Piety Church, Mardol, Goa"] <- 1866
churches_with_addresses_sf$built_date[churches_with_addresses_sf$church_name == "The Holy Magi Kings Church, Reis Magos, Goa"] <- 1555 
churches_with_addresses_sf$built_date[churches_with_addresses_sf$church_name == "St. John of the Cross Church, Sanquelim, Goa"] <- 1826 

# St. Francis Xavier Church, Duler, Mapusa, Goa - couldn't find it 
# St. Anthony Church, Vagator, Goa - couldn't find it 
# St. John the Baptist Church, Carambolim, Goa - couldn't find it
# Our Lady, Mother of the Poor Church, Tilamola, Goa - couldn't find it
# Our Lady of the Rosary Church, Caranzalem, Goa - couldn't find it
# St. Sebastian Church, Tormas, Goa - couldn't find it


df <- churches_with_addresses_sf %>% select(-geocode_result)

df <- df %>%
  mutate(female_orders = ifelse(
    str_detect(order, regex("sister|women|female|woman", ignore_case = TRUE)), 
    1, 0
  ))

saveRDS(df, file = "church_data_coords_sf.rds")


churches_with_addresses$built_date[churches_with_addresses$church_name == "Our Lady of the Rosary Church, Curca, Goa"] <- 1984
churches_with_addresses$built_date[churches_with_addresses$church_name == "Our Lady of Refuge Church, Mandur, Goa"] <- 1710
churches_with_addresses$built_date[churches_with_addresses$church_name == "St Thomas Church, Old Goa"] <- 1596
churches_with_addresses$built_date[churches_with_addresses$church_name == "St. Mathias the Apostle Church, Malar, Goa"] <- "between 1590 and 1597"
churches_with_addresses$built_date[churches_with_addresses$church_name == "Our Lady, Mother of God Church, Saligao, Goa"] <- 1867
churches_with_addresses$built_date[churches_with_addresses$church_name == "Our Lady of the Rosary Church, Sadolxem, Goa"] <- "between 1544 and 1547"
churches_with_addresses$built_date[churches_with_addresses$church_name == "Our Lady of Piety Church, Mardol, Goa"] <- 1866
churches_with_addresses$built_date[churches_with_addresses$church_name == "The Holy Magi Kings Church, Reis Magos, Goa"] <- 1555 
churches_with_addresses$built_date[churches_with_addresses$church_name == "St. John of the Cross Church, Sanquelim, Goa"] <- 1826 

df_other <- churches_with_addresses %>% select(-geocode_result)
df_other <- df_other %>%
  mutate(female_orders = ifelse(
    str_detect(order, regex("sister|women|female|woman", ignore_case = TRUE)), 
    1, 0
  ))

write.csv(df_other, "church_data_latlongs.csv", row.names = FALSE)
