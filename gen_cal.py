#!/usr/bin/env python3

import datetime

import pytz
import icalendar
from dateutil.parser import parse

import gen_cards

presentations = gen_cards.load_json()
cal = icalendar.Calendar()

now = datetime.datetime.utcnow()

for talk_id, talk in presentations.items():
    dt_start = parse(f"{talk['day']} 2017 {talk['time']} CET").astimezone(pytz.utc)
    dt_end = dt_start + datetime.timedelta(minutes=talk['duration'])

    event = icalendar.Event()
    event.add('summary', talk['title'])
    event.add('dtstamp', dt_start)
    event.add('dtstart', dt_start)
    event.add('dtend', dt_end)
    event.add('uid', talk_id)
    event.add('location', talk['location'])
    event.add('description', f"Speakers: {talk['speakers']}")
    cal.add_component(event)

print(cal.to_ical().decode('utf8'))
