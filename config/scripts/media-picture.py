#!/usr/bin/env python3

import json,re,sys
from PIL import Image,ImageOps


def convert(source, output, options):
    with Image.open(source) as original:
        image=ImageOps.exif_transpose(original)
        if options.get('rotate'):
            angle=float(options.get('angle',90))
            if not -360<=angle<=360: raise ValueError('Angle must be between -360 and 360')
            image=image.rotate(-angle,resample=Image.Resampling.BICUBIC,expand=True)
        if options.get('mirror'): image=ImageOps.mirror(image)
        if options.get('grayscale'): image=ImageOps.grayscale(image)
        if options.get('resize'):
            match=re.fullmatch(r'\s*([1-9]\d{0,4})(?:\s*[xX×]\s*([1-9]\d{0,4}))?\s*',str(options.get('size','')))
            if not match: raise ValueError('Enter width or width × height')
            w=int(match[1]);h=int(match[2]) if match[2] else max(1,round(image.height*w/image.width))
            if not 1<=w<=16384 or not 1<=h<=16384:raise ValueError('Dimensions must be 1–16384 pixels')
            image=image.resize((w,h),Image.Resampling.LANCZOS)
        fmt=options['format']
        if fmt in ['jpg','bmp'] and image.mode not in ['RGB','L']:
            rgba=image.convert('RGBA');image=Image.new('RGB',image.size,'white');image.paste(rgba,mask=rgba.getchannel('A'))
        params={'quality':92} if fmt in ['jpg','webp'] else {}
        if not options.get('strip') and fmt in ['jpg','png','webp','tiff']:
            exif=image.getexif()
            if exif:params['exif']=exif.tobytes()
            if original.info.get('icc_profile'):params['icc_profile']=original.info['icc_profile']
        with open(output,'xb') as destination:
            image.save(destination,format={'jpg':'JPEG','tiff':'TIFF'}.get(fmt,fmt.upper()),**params)

if __name__=='__main__':convert(sys.argv[1],sys.argv[2],json.loads(sys.argv[3]))
