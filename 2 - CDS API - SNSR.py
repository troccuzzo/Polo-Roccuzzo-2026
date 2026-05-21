import cdsapi

client = cdsapi.Client()

for year in range(2012, 2027):

    
    dataset = "reanalysis-era5-land"
    request = {
        "variable": [
            "surface_net_solar_radiation"
        ],
        "year": str(year),
        "month": [
            "01", "02", "03",
            "04", "05", "06",
            "07", "08", "09",
            "10", "11", "12"
        ],

        "day": [
            "01", "02", "03",
            "04", "05", "06",
            "07", "08", "09",
            "10", "11", "12",
            "13", "14", "15",
            "16", "17", "18",
            "19", "20", "21",
            "22", "23", "24",
            "25", "26", "27",
            "28", "29", "30",
            "31"
        ],
        "time": "00:00",
        "data_format": "netcdf",
        "download_format": "zip",
        "area": [47, 6, 36, 19]
    }

    output_filename = f"era5_land_radiation_{year}.zip"

    print(f"Requesting data for year {year}...")
    
    # SPECIFY THE DIRECTORY WHERE THE SNSR FILE SHOULD BE SAVED.
    client.retrieve(dataset, request, target=f"_{year}.nc")

    print(f"Data for year {year} saved to {output_filename}.")