# ERRM: Effective Relaxing Response Model

This repository contains the numerical implementation and dataset for the **Effective Relaxing Response Model (ERRM)**, a minimal phenomenological approach to galactic rotation curves.

## 📌 Overview
The ERRM proposes that the observed "dark matter" effect emerges from an effective baryonic response. 
Key results from our study of 100 SPARC galaxies:
- **78% Success Rate** ($\chi^2 < 2$) with a single universal parameter ($a_0$).
- **Statistical Robustness**: Median $\chi^2 = 1.8$ (Bootstrap IC 95%: $\pm 4\%$).
- **Open Science**: Fully reproducible code and data.

## 🚀 Getting Started
To reproduce the results presented in the paper, run the analysis script:
```bash
python scripts/errm_v6.py
