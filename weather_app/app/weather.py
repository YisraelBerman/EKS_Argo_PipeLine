from datetime import date
import requests
import json
from boto3 import client
import boto3
import os
import sys
from pathlib import Path
from flask import Flask, render_template, request, Response, session
from decimal import *

app = Flask(__name__)
app.secret_key = "anyrandomstring"

@app.route('/', methods = ['GET', 'POST'])
def index():
    data = {'location': None,
            'try': 0
            }

    #list of names of days of week starting today
    today = date.today().weekday()
    weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    weekdays = weekdays[today:] + weekdays[:today]
    data['days'] = weekdays
    #get info from api. check if entered correct location
    try:
        if request.method == 'POST':
            location = request.form['city']
            data['location'] = location
            url = 'https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/weatherdata/forecast?'
            response = requests.get(url, params=f"locations={data['location']}&aggregateHours=12&forecastDays=7&unitGroup=metric&contentType=json&key=YVN2F9P3A4EAK64RKT2GF8KFS")
            data['info'] = response.json()['locations'][f"{data['location']}"]
            #setup data for order of day and night
            if data['info']['values'][0]['datetimeStr'].split("T")[1] == '18:00:00-05:00':
                data['first'] = 'Night'
                data['second'] = 'Day'
            else:
                data['first'] = 'Day'
                data['second'] = 'Night'
            session['jdata'] = response.json()['locations'][f"{data['location']}"]
            session['gdata'] = data

    #send back to start for new location
    except requests.exceptions.JSONDecodeError:
        data = {'location': None}
        data['try'] = 1
    
    return render_template('index.html', data = data)

def get_client():
    return client(
        's3',
        'us-east-1',
        aws_access_key_id=os.environ.get('key_id'),
        aws_secret_access_key=os.environ.get('access_key')
    )

@app.route('/your_flask_route')
def Download_image():
    
    s3 = get_client() 
    file = s3.get_object(Bucket='myyisbucket', Key='weatherimage.jpg')
    return Response(
        file['Body'].read(),
        mimetype='image/jpg',
        headers={"Content-Disposition": "attachment;filename=image.jpg"}
    )

   
    



    
    


if __name__ == '__main__':
    app.run(host="0.0.0.0")
