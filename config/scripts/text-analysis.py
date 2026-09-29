
import re,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent/'vendor'))
NAMES=dict(zip('af ar bg bn ca cs cy da de el en es et fa fi fr gu he hi hr hu id it ja kn ko lt lv mk ml mr ne nl no pa pl pt ro ru sk sl so sq sv sw ta te th tl tr uk ur vi zh-cn zh-tw'.split(),
'Afrikaans|Arabic|Bulgarian|Bengali|Catalan|Czech|Welsh|Danish|German|Greek|English|Spanish|Estonian|Persian|Finnish|French|Gujarati|Hebrew|Hindi|Croatian|Hungarian|Indonesian|Italian|Japanese|Kannada|Korean|Lithuanian|Latvian|Macedonian|Malayalam|Marathi|Nepali|Dutch|Norwegian|Punjabi|Polish|Portuguese|Romanian|Russian|Slovak|Slovenian|Somali|Albanian|Swedish|Swahili|Tamil|Telugu|Thai|Tagalog|Turkish|Ukrainian|Urdu|Vietnamese|Chinese (Simplified)|Chinese (Traditional)'.split('|')))
def analyze(text):
    
    words=sum(1 for _ in re.finditer(r"[^\W_]+(?:['’\-][^\W_]+)*",text,re.UNICODE))
    result=dict(words=words,characters=len(text),language='Unknown',code='')
    if sum(c.isalpha() for c in text)<5:return result
    from langdetect import DetectorFactory,detect_langs,LangDetectException
    DetectorFactory.seed=0
    try:
        candidates=detect_langs(text[:50000])
        if candidates and candidates[0].prob>=.70:
            code=candidates[0].lang;result.update(code=code,language=NAMES.get(code,code))
    except LangDetectException:pass
    return result
