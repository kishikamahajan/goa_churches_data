library(tidyverse)
library(tidygeocoder)
library(sf)
library(tmap)
library(ggmap)

# Reading the file produced by the python script
churches <- readr::read_csv("/Users/kishikamahajan/Desktop/church_data_updated.csv")

# Registering Google API
register_google(key = "---")

# Getting the lats and longs for addresses of each church
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

# PLotting the points on the Indian map
tmap_mode("view")
tm_shape(churches_with_addresses_sf) + tm_dots()

df <- churches_with_addresses_sf %>% select(-geocode_result)

df <- df %>%
  mutate(female_orders = ifelse(
    str_detect(order, regex("sister|women|female|woman", ignore_case = TRUE)), 
    1, 0
  ))

saveRDS(df, file = "church_data_coords_sf.rds")
