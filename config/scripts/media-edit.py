
import re
import uuid
import sys
import json
from pathlib import Path
from fractions import Fraction


def command(source, options):
    if not isinstance(options, dict):
        raise ValueError('Invalid media options')
    kind = options.get('kind', 'audio' if options.get('format') == 'mp3' else 'video')
    if kind == 'image': kind = 'picture'
    formats = {'video': ['mp4','mkv','webm','mov'], 'audio': ['mp3','m4a','flac','wav','opus','ogg'], 'picture': ['png','jpg','webp','tiff','bmp']}
    fmt = options.get('format', formats.get(kind, [''])[0])
    if kind not in formats or fmt not in formats[kind]:
        raise ValueError('Unsupported output format')
    audio = kind == 'audio'
    output = source.with_name(source.stem + '-edited-' + uuid.uuid4().hex[:8] + '.' + fmt)
    if kind == 'picture':
        return [sys.executable, str(Path(__file__).with_name('media-picture.py')), str(source), str(output), json.dumps(options)], output
    args = ['ffmpeg', '-hide_banner', '-nostdin', '-n', '-i', str(source)]
    if options.get('trim'):
        def seconds(value):
            if not re.fullmatch(r'\d+(?::[0-5]\d){0,2}(?:\.\d+)?', str(value)):
                raise ValueError('Enter seconds or HH:MM:SS for start and duration')
            result = 0.0
            for part in str(value).split(':'):
                result = result * 60 + float(part)
            return result
        start = seconds(options.get('start', '0'))
        duration = seconds(options.get('duration', '0'))
        if duration <= 0:
            raise ValueError('Duration must be greater than zero')
        args += ['-ss', str(start), '-t', str(duration)]
    if audio:
        codecs = {'mp3':['libmp3lame','-q:a','2'], 'm4a':['aac','-b:a','192k'], 'flac':['flac'], 'wav':['pcm_s16le'], 'opus':['libopus','-b:a','160k'], 'ogg':['libvorbis','-q:a','6']}
        args += ['-vn', '-c:a'] + codecs[fmt]
        filters = []
        if options.get('mute'):filters.append('volume=0')
        if options.get('normalize'): filters.append('loudnorm=I=-16:TP=-1.5:LRA=11')
        if options.get('volume'):
            value = float(options.get('gain', 100))
            if not 0 <= value <= 300: raise ValueError('Volume must be 0–300%')
            filters.append(f'volume={value/100}')
        if filters: args += ['-af', ','.join(filters)]
        if options.get('mono'): args += ['-ac','1']
    else:
        filters = []
        if options.get('rotate'):
            angle=float(options.get('angle',90))
            if not -360<=angle<=360: raise ValueError('Angle must be between -360 and 360')
            if angle%360==90: filters.append('transpose=1')
            elif angle%360==270: filters.append('transpose=2')
            elif angle%360==180: filters.extend(['hflip','vflip'])
            elif angle%360: filters.append(f'rotate={angle}*PI/180:ow=ceil(rotw({angle}*PI/180)/2)*2:oh=ceil(roth({angle}*PI/180)/2)*2:c=black')
        if options.get('mirror'):
            filters.append('hflip')
        if options.get('resize'):
            size = re.fullmatch(r'\s*([1-9]\d{0,4})(?:\s*[xX×]\s*([1-9]\d{0,4}))?\s*', str(options.get('size', '')))
            if not size:
                raise ValueError('Enter a width or width × height, e.g. 1280 or 1080x1080')
            width, height = int(size[1]), int(size[2]) if size[2] else -2
            if any(v != -2 and (v < 2 or v > 16384 or v % 2) for v in (width, height)):
                raise ValueError('Use even dimensions from 2 to 16384 pixels')
            filters += [f'scale={width}:{height}', 'setsar=1']
        if options.get('fps'):
            value = str(options.get('rate', ''))
            if not re.fullmatch(r'\d+(?:\.\d+|/\d+)?', value):
                raise ValueError('Enter FPS, e.g. 30, 59.94 or 30000/1001')
            try:
                rate = Fraction(value)
            except (ValueError, ZeroDivisionError):
                raise ValueError('Invalid FPS') from None
            if not 1 <= rate <= 1000:
                raise ValueError('FPS must be between 1 and 1000')
            filters.append(f'fps={rate.numerator}/{rate.denominator}')
        if filters:
            args += ['-vf', ','.join(filters)]
        args += ['-c:v', 'libvpx-vp9', '-crf', '30', '-b:v', '0'] if fmt == 'webm' else ['-c:v', 'libx264', '-crf', '18', '-preset', 'medium']
        args += ['-pix_fmt','yuv420p']
        args += ['-an'] if options.get('mute') else ['-c:a', 'libopus' if fmt == 'webm' else 'aac', '-b:a', '192k']
        if fmt in ['mp4','mov']: args += ['-movflags', '+faststart']
    if options.get('strip'):
        args += ['-map_metadata','-1','-map_metadata:s','-1','-map_chapters','-1']
    return args + [str(output)], output
