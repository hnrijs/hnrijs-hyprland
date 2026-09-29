#!/usr/bin/env python3
import json,os,re,subprocess,sys,tempfile,urllib.parse
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo,available_timezones
SCRIPTS=Path(__file__).resolve().parent


def run(args,**kwargs):
    result=subprocess.run(args,capture_output=True,check=False,**kwargs)
    if result.returncode:raise ValueError((result.stderr.decode(errors='replace') if isinstance(result.stderr,bytes) else result.stderr).strip() or 'Command failed')
    return result.stdout


def path(value):
    if value.startswith('file:'):value=urllib.parse.unquote(urllib.parse.urlsplit(value).path)
    return Path(value).expanduser().resolve(strict=True)


def copy(text):
    subprocess.run(['wl-copy'],input=text.encode(),stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,check=True,timeout=5)


def ocr(source,language):
    if not re.fullmatch(r'[a-zA-Z0-9_]+(?:\+[a-zA-Z0-9_]+)*',language):raise ValueError('Invalid OCR language')
    data=run(['magick','-limit','memory','256MiB','-limit','map','512MiB',str(source)+'[0]','-auto-orient','-resize','3000x3000>','-colorspace','Gray','-normalize','png:-'],timeout=30)
    text=run(['tesseract','stdin','stdout','-l',language,'--psm','3'],input=data,timeout=60).decode().strip()
    if text:copy(text)
    return {'text':text,'message':'Copied Text' if text else 'No Text Found'}


def main(action,*args):
    if action in ['translate','analyze','copy-text']:
        import importlib.util
        spec=importlib.util.spec_from_file_location('text_analysis',SCRIPTS/'text-analysis.py')
        analysis=importlib.util.module_from_spec(spec);spec.loader.exec_module(analysis)
        text=sys.stdin.read() if (not args or args[-1]=='--stdin') else args[-1]
        if action=='copy-text':copy(text);return {}
        if action=='analyze':return analysis.analyze(text)
        source,target=args[:2]
        if not all(re.fullmatch(r'[A-Za-z]{2,8}(?:-[A-Za-z]{2,8})?',v) for v in [source,target]):raise ValueError('Use language codes, e.g. auto, en, lv, de')
        if not text.strip():raise ValueError('Enter text to translate')
        if len(text)>20000:raise ValueError('Translate supports up to 20,000 characters per request')
        details=analysis.analyze(text)
        
        with tempfile.TemporaryDirectory(prefix='hshell-translate-') as tmp:
            sourcefile=Path(tmp)/'input.txt';sourcefile.write_text(text)
            result=run(['trans','-b','-no-ansi','-no-autocorrect','-s',source,'-t',target,'-i',str(sourcefile)],text=True,timeout=90)
        return dict(details,text=result.strip(),sourceLanguage=details['language'] if source=='auto' else analysis.NAMES.get(source,source),targetLanguage=analysis.NAMES.get(target,target))
    if action=='world':
        import importlib.util
        spec=importlib.util.spec_from_file_location('world',SCRIPTS/'world.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        return module.main(args[0])
    if action=='timezone':
        zone=ZoneInfo(args[0]);now=datetime.now(zone)
        return {'text':now.strftime('%H:%M:%S'),'date':now.strftime('%A, %d %B %Y'),'zone':args[0],'offset':now.strftime('UTC%z')}
    if action=='zones':return {'zones':sorted(available_timezones())}
    if action=='ocr-languages':
        text=run(['tesseract','--list-langs'],text=True)
        return {'languages':[v for v in text.splitlines() if re.fullmatch('[A-Za-z0-9_]+',v) and v!='osd']}
    if action=='ocr-file':return ocr(path(args[0]),args[1])
    if action in ['ocr-region','ruler']:
        picker=subprocess.run(['slurp']+(['-f','%w x %h'] if action=='ruler' else []),capture_output=True,text=True,timeout=30)
        if picker.returncode or not picker.stdout.strip():return {'message':'Cancelled'}
        if action=='ruler':
            value=picker.stdout.strip();copy(value);return {'text':value}
        with tempfile.TemporaryDirectory(prefix='hshell-ocr-') as tmp:
            image=Path(tmp)/'region.png';run(['grim','-g',picker.stdout.strip(),str(image)],timeout=15)
            return ocr(image,args[0])
    if action=='phone-devices':
        output=run(['adb','devices','-l'],text=True)
        return {'devices':[dict(serial=line.split()[0],state=line.split()[1],detail=' '.join(line.split()[2:])) for line in output.splitlines()[1:] if len(line.split())>=2]}
    if action=='phone-start':
        serial=args[0]
        devices=main('phone-devices')['devices']
        if not any(d['serial']==serial and d['state']=='device' for d in devices):raise ValueError('Authorize USB debugging on the phone first')
        subprocess.Popen(['scrcpy','--serial',serial],start_new_session=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        return {'message':'Phone Mirror Started'}
    raise ValueError('Unknown utility action')

if __name__=='__main__':
    try:print(json.dumps(main(*sys.argv[1:])))
    except Exception as error:print(str(error),file=sys.stderr);sys.exit(1)
