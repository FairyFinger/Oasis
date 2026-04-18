# SPARC Dataset - ERRM Analysis v6

This folder contains the processed data from the SPARC database used to validate the ERRM model.

## Columns Description
- **Name**: Galaxy name (SPARC catalog).
- **Distance_Mpc**: Distance in Megaparsecs.
- **Vobs_max**: Maximum observed rotation velocity (km/s).
- **Vbar_max**: Maximum baryonic velocity (calculated from gas + stars).
- **Chi2_ERRM**: Reduced Chi-square for the ERRM model.
- **Success**: 1 if Chi2 < 2 (Success), 0 otherwise (Failure).

## Methodology
Data is sourced from Lelli et al. (2016). The Chi2 values are generated using the `errm_v6.py` script located at the root of this repository.
