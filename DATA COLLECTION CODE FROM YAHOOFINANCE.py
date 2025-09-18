import yfinance as yf
import pandas as pd

# Define the stock tickers and date range
tickers = ['NVDA', 'MSFT', 'GOOG', 'AAPL', '^IXIC']
start_date = '2023-07-01'
end_date = '2025-04-30'

# Download and save data
for ticker in tickers:
    data = yf.download(ticker, start=start_date, end=end_date)
    data.to_csv(f"{ticker}_stock_data.csv")
    print(f"Downloaded {ticker} data.")
