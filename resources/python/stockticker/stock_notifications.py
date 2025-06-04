#!/usr/bin/env python
# -*- coding: utf-8 -*-

# ~~~~~
# == Setup ==
# % pip install [--user] requests
# % pip install [--user] schedule
# % pip install [--user] yfinance
#
# Make Python-script executable:
# % chmod +x ./stock_notifications.py
#
# == Usage ==
# one time (without any threshold):
# % python3 ./stock_notifications.py "BTC-USD"
#
# running as a service (every 11 hours, if threshold above 99.9):
# % nohup python3 ./stock_notifications.py "TSLA" 99.9 39600 $
#
# ~~~~~
# Original source: https://codeburst.io/indian-stock-market-price-notifier-bot-telegram-92e376b0c33a
# Resources:
#  - Symbol: https://finance.yahoo.com/quote/TSLA?p=TSLA
#  - YF for Python: https://pypi.org/project/fix-yahoo-finance/0.1.30/
#  - YF4P docu: https://aroussi.com/post/python-yahoo-finance
#  - Telegram Bot API: https://core.telegram.org/bots/api#sendmessage
# ~~~~~
import sys
import time
import threading
import schedule
import json
import yfinance as yf
import requests
import urllib.parse
import os

# Check for stock symbol as 1st parameter
if len(sys.argv) < 3:
    print("Missing parameters. Usage: script.py SYMBOL BOT_TOKEN CHAT_ID [THRESHOLD] [INTERVAL]")
    quit()
else:
    symbol=sys.argv[1]
    bot_token = sys.argv[2]
    bot_chatID = sys.argv[3]

# Check for and validate Telegram Bot-Token and Chat-ID
if len(bot_token) < 40 or len(bot_chatID) < 5:
    print("Invalid BOT_TOKEN or CHAT_ID values!")
    quit()

# Check for optional price notification threshold as 4th parameter
if len(sys.argv) <= 4:
    # Default: very low threshold of 0.01 (so it needs at least a change)
    price_threshold = 0.01
elif float(sys.argv[4]) > 0.00:
    price_threshold = float(sys.argv[4])
else:
    print("Invalid 4th parameter: must be a positive number as price change threshold (e.g. 1.00).")
    quit()

# Check for optional timer seconds as 5th parameter
if len(sys.argv) <= 5:
    # Default: 1 minute = 60 seconds
    repeat=60
elif int(sys.argv[5]) >= 1:
    repeat=int(sys.argv[5])
else:
    print("Invalid 5th parameter: must be a number representing seconds to re-run script (e.g. 3600).")
    quit()

# Global vars
currency=''
price_initial=0
price=0

# Get currency for symbol
if currency == '':
    try:
        #print(f"========== DEBUG: Getting currency info for {symbol}...")
        ticker_meta = yf.Ticker(symbol)
        ticker_info = ticker_meta.info

        # Try different ways to get currency
        if 'currency' in ticker_info:
            currency = ticker_info['currency']
        elif 'financialCurrency' in ticker_info:
            currency = ticker_info['financialCurrency']
        else:
            # Default currency if none found
            print(f"No currency info found for {symbol}, using USD")
            currency = 'USD'

    except Exception as e:
        print(f"Error getting currency for {symbol}: {e}")
        #print("========== DEBUG: Using USD as default currency")
        currency = 'USD'

#print(f"========== DEBUG: Using currency: {currency} for {symbol}")

def getStock():
    global symbol
    global price_threshold
    global currency
    global price_initial
    global price

    try:
        # Get ticker data
        ticker = yf.download(symbol, period="1d", auto_adjust=True)
        # Check if we got data
        if ticker.empty:
            print(f"No data received for {symbol}")
            # Mark as unhealthy
            with open("/tmp/unhealthy", "w") as f:
                f.write("yfinance failed\n")
            return

        # Get the latest close price (last row, Close column)
        price = float(ticker['Close'].iloc[-1].iloc[0])

        # Get initial price if not set
        if price_initial == 0:
            price_initial = float(ticker['Open'].iloc[0].iloc[0])

        # Round after conversion
        price = round(price, 2)
        price_initial = round(price_initial, 2)

        # Debug output:
        #print('========== DEBUG: price == price_initial: '+symbol+' ('+currency+')')
        #print('========== DEBUG: Price initial: '+str(price_initial))
        #print('========== DEBUG: Price current: '+str(price))

        if price == price_initial:
            #print('========== DEBUG: price == price_initial: '+str(price))
            price_diff = 0
            price_change_str = ''
            price_diff_str = ''
        elif price > price_initial:
            #print('========== DEBUG: price > price_initial: '+str(price))
            price_diff = round(price - price_initial, 2)
            price_change_str = "📈up"
            price_diff_str = f"({price_change_str} +{price_diff})"
        else:
            #print('========== DEBUG: other: '+str(price))
            price_diff = round(price_initial - price, 2)
            price_change_str = "📉dip"
            price_diff_str = f"({price_change_str} -{price_diff})"

        # Price diff above given threshold AND change of stock price
        if abs(price_diff) >= price_threshold:
            #print('========== DEBUG: abs(price_diff) >= price_threshold: '+str(symbol))
            message=symbol+" @ *"+currency+" "+str("{0:,.2f}".format(price)).replace(',', '\'')+"* "+price_diff_str
            message=message.replace("-","\-")
            message=message.replace("+","\+")
            message=message.replace(".","\.")
            message=message.replace("(","\(")
            message=message.replace(")","\)")
            message=message.replace("?","\?")
            message=message.replace("^","\^")
            message=message.replace("$","\$")
            message=urllib.parse.quote_plus(message)

            send='https://api.telegram.org/bot' + bot_token + '/sendMessage?parse_mode=MarkdownV2&disable_notification=true&chat_id=' + bot_chatID + '&text=' + message
            #print('========== DEBUG: send: '+send)
            response=requests.get(send)
            #print('========== DEBUG: response: '+str(response))
            # Set new price_initial to check against future changes
            price_initial = price
    except Exception as e:
        print(f"Error in yfinance: {e}")

        # Signal an "unhealthy" state to Docker
        with open("/tmp/unhealthy", "w") as f:
            f.write("yfinance exception\n")
        return

while True:
    getStock()
    time.sleep(repeat)
