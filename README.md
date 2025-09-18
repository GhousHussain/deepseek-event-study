# DeepSeek Event Study: U.S. Tech Stock Reactions

This repository contains code, data, and EViews workfiles for the MSc Business Analytics dissertation:
**“The Financial Market Impact of AI Disruptors: Event Study of DeepSeek’s Emergence.”**

## Overview
- Event date: **2025-01-27** (DeepSeek overtakes ChatGPT on U.S. App Store)
- Firms: **AAPL, MSFT, NVDA**
- Windows: primary **[-1,+1]**, robustness **[-5,+5]**
- Methods: Market model → AR & CAR; Patell Z; BMP; bootstrap (1,000 resamples)
- Tools: **Python** (data, bootstrap), **EViews** (estimation, graphs)

## Repo Structure
See `/data`, `/src`, `/eviews`, `/results`, `/docs` in this repository.

## Quickstart (Python)
```bash
conda env create -f environment.yml   # or: pip install -r requirements.txt
conda activate deepseek-event-study
python src/00_download_prices.py
python src/01_make_returns.py
python src/02_bootstrap_car.py
python src/03_figures.py
