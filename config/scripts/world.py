
import json,re,urllib.parse,urllib.request
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

def coordinates(zone):
    base=Path('/usr/share/zoneinfo')
    canonical=str((base/zone).resolve().relative_to(base.resolve()))
    for name in ['zone1970.tab','zone.tab']:
        table=base/name
        if not table.exists():continue
        for line in table.read_text().splitlines():
            if not line or line.startswith('#'):continue
            parts=line.split('\t')
            if parts[2] not in [zone,canonical]:continue
            match=re.fullmatch(r'([+-])(\d{2})(\d{2})(\d{2})?([+-])(\d{3})(\d{2})(\d{2})?',parts[1])
            if match:
                a=match.groups();lat=(int(a[1])+int(a[2])/60+int(a[3] or 0)/3600)*(1 if a[0]=='+' else -1)
                lon=(int(a[5])+int(a[6])/60+int(a[7] or 0)/3600)*(1 if a[4]=='+' else -1)
                return lat,lon,parts[2].split('/')[-1].replace('_',' ')
    return None

def main(zone):
    now=datetime.now(ZoneInfo(zone))
    result=dict(text=now.strftime('%H:%M'),date=now.strftime('%A, %d %B %Y'),zone=zone,offset=now.strftime('UTC%z'))
    where=coordinates(zone)
    if not where:return dict(result,weatherError='No weather location for this timezone')
    lat,lon,city=where;result['city']=city
    params=urllib.parse.urlencode(dict(latitude=lat,longitude=lon,timezone=zone,current='temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m',forecast_days=1))
    try:
        with urllib.request.urlopen('https://api.open-meteo.com/v1/forecast?'+params,timeout=10) as response:data=json.load(response)
        current=data['current'];code=current['weather_code']
        label='Clear' if code==0 else 'Partly Cloudy' if code in [1,2] else 'Overcast' if code==3 else 'Fog' if code in [45,48] else 'Thunderstorm' if code>=95 else 'Snow' if code in [71,73,75,77,85,86] else 'Rain'
        result.update(temperature=current['temperature_2m'],feels=current['apparent_temperature'],humidity=current['relative_humidity_2m'],wind=current['wind_speed_10m'],condition=label,weatherTime=current['time'])
    except Exception:result['weatherError']='Weather unavailable · try again later'
    return result
