from datetime import datetime
from zoneinfo import ZoneInfo


def snapshot():
    with open('/etc/localtime', 'rb') as source:
        zone = ZoneInfo.from_file(source)
    now = datetime.now(zone)
    return {'time': now.strftime('%H:%M'), 'date': now.strftime('%a, %b ') + str(now.day),
            'year': now.year, 'month': now.month, 'day': now.day}
