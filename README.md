# Polo, Roccuzzo (2026)
The following repository provides the database and replication package of Polo, Roccuzzo (2026) [link]. 
Any question about these files should be addressed to tommaso.roccuzzo@duke.edu or to michele.polo@unibocconi.it.

All data sources are open access and easily retrievable by interested parties. Links pointing to the necessary data sources are provided at the end of this README file.

For our analyisis, we have relied on:
- R version 4.4.3
- Stata19
- Python 3.13.3


# Available Files
- File 1 - CDS API HDD.py to download daily mean temperatures from the ERA5-Land database;
- File 2 - CDS API SNSR.py to download total daily surface net solar radiation from the ERA5-Land database;
- File 3 - Dataset Creation.R to combine all imputs and create the dataset of analysis to be then loaded into Stata;
- File 4 - Replication.do to perform the regression/statystical analysis.
- Replication_Daily.xlsx, the data set of analysis at daily resolution.
- Replication_Monthly.xlsx, the data set of analysis at monthly resolution.


In order to correctly replicate our entire study one should:
1) download all inputs reported in the Data Sources;
2) combine all sources with File 3 - Dataset Creation.R to create the working data sets (pay attention to specific comments in the file to ensure correct replication of the data sets' creation);
3) run File 4 - Replication.do file with the daily and monthly datasets created.


Notice that both data sets of analysis (Replication_Daily.xlsx and Replication_Monthly.xlsx) are also already provided in their final format. Replication can be carried out directly using File 4 - Replication.do and these two data sets.

# Data Sources
1) Daily gas balances: https://jarvis.snam.it/public-data?pubblicazione=Bilancio%20Definitivo&periodo=2025&lang=it. Download all gas balances from Jan-2012 to Dec-2025 included;
2) Daily mean temperatures: https://cds.climate.copernicus.eu/datasets/reanalysis-era5-land?tab=overview. Use File 1 to download the NetCDF files;
3) Daily total surface net solar radiation: https://cds.climate.copernicus.eu/datasets/reanalysis-era5-land?tab=overview. Use File 2 to download the NetCDF files;
4) Monthly price index: https://esploradati.istat.it/databrowser/#/it/dw/categories/IT1,Z0400PRI,1.0/PRI_CONWHONAT/PRI_CONWHONAT_BRI/DCSP_NICUNOBB2010/IT1,167_33_DF_DCSP_NICUNOBB2010_3,1.0 and https://esploradati.istat.it/databrowser/#/it/dw/categories/IT1,Z0400PRI,1.0/PRI_CONWHONAT/DCSP_NIC1B2015/IT1,167_744_DF_DCSP_NIC1B2015_4,1.0. Download both files;
5) Italian population by province: https://esploradati.istat.it/databrowser/#/it/dw/categories/IT1,POP,1.0/POP_POPULATION/DCIS_POPRES1/IT1,22_289_DF_DCIS_POPRES1_1,1.0. Download the 2024 file;
6) EUROSTAT prices: https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_202__custom_20359708/default/table. Download the prices for Italian consumers in BAND D2, ALL TAXES AND LEVIES INCLUDED;
7) TTF prices: https://www.investing.com/commodities/ice-dutch-ttf-gas-c1-futures. Download the historical daily prices from June 1st, 2011 to December 31st 2025.

Cite as:

Polo, Michele, and Roccuzzo, Tommaso. (2026). Replication Package for “And Yet it Moves: A Study of Natural Gas Consumption at the Turn of the 2022 Energy Crisis in Italy”. GitHub Repository. Available at: https://github.com/troccuzzo/Polo-Roccuzzo-2026



