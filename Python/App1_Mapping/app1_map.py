import folium
import pandas
from statistics import mean

def color_producer(elev, elev_avg):
    # Set color of marker based on elevation compared to the average
    if elev < (elev_avg * 0.67):
        # Short
        return 'green'
    elif elev < (elev_avg * 1.33):
        # Medium
        return 'blue'
    else:
        # Tall
        return 'purple'

# Create empty map of USA
map = folium.Map(location=[38.58, -99.09], zoom_start=5, tiles="Stamen Terrain")

# Create feature groups for volcanoes and population layers
volcano_fg = folium.FeatureGroup(name="Volcanoes")
pop_fg = folium.FeatureGroup(name="Population")

# Load volcano data from text file
volcano_data = pandas.read_csv("Volcanoes.txt")
volcano_lat = list(volcano_data["LAT"]) 
volcano_lon = list(volcano_data["LON"])
volcano_elev = list(volcano_data["ELEV"])
volcano_name = list(volcano_data["NAME"])

# Compute average for color production
volcano_elev_avg = round(mean(volcano_elev), 0)

# Configure html so that the popup windows include the volcano's name and height, including a link to search for specific volcanoes
html = """
Volcano name:<br>
<a href="https://www.google.com/search?q=%%22%s%%22" target="_blank">%s</a><br>
Height: %s m
"""

# Add markers to map for volcanoes
for lat, lon, elev, name in zip(volcano_lat, volcano_lon, volcano_elev, volcano_name):
    iframe = folium.IFrame(html=html % (name + " volcano", name, elev), width=200, height=100)
    volcano_fg.add_child(folium.CircleMarker(location=[lat, lon], radius=6, fill=True, popup=folium.Popup(iframe), fill_color=color_producer(elev, volcano_elev_avg), color='grey', fill_opacity=0.7))

# Add data for population of countries, loaded from json file. Set fillColor by population
pop_fg.add_child(folium.GeoJson(data=open('world.json', 'r', encoding='utf-8-sig').read(), 
style_function=lambda x: {'fillColor':'green' if x['properties']['POP2005'] < 10000000 else 'orange' if 10000000 <= x['properties']['POP2005'] < 20000000 else 'blue'}))

# Add layers and layer control to map
map.add_child(volcano_fg)
map.add_child(pop_fg)
map.add_child(folium.LayerControl())

# Save map file
map.save("generated_map.html")