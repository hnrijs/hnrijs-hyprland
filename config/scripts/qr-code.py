import base64
import io
import os
from pathlib import Path
import subprocess
import urllib.parse


def main(action, text, destination=''):
    import qrcode
    if not text.strip():
        raise ValueError('Enter text or a link')
    if len(text.encode('utf-8')) > 2000:
        raise ValueError('Use at most 2000 UTF-8 bytes')
    code = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_M, box_size=8, border=4)
    code.add_data(text)
    code.make(fit=True)
    image = code.make_image(fill_color='black', back_color='white')
    stream = io.BytesIO()
    image.save(stream, format='PNG')
    data = stream.getvalue()
    if action == 'generate':
        return {'url': 'data:image/png;base64,' + base64.b64encode(data).decode('ascii')}
    if action == 'copy':
        subprocess.run(['wl-copy', '--type', 'image/png'], input=data, check=True)
        return {'message': 'QR Code Copied'}
    if action == 'save':
        if destination.startswith('file:'):
            url = urllib.parse.urlparse(destination)
            if url.netloc not in ['', 'localhost']:
                raise ValueError('Choose a local file')
            destination = urllib.parse.unquote(url.path)
        path = Path(destination).expanduser()
        if not path.is_absolute() or path.suffix.lower() != '.png':
            raise ValueError('Choose a PNG file')
        with path.open('wb') as output:
            output.write(data)
            output.flush()
            os.fsync(output.fileno())
        return {'message': 'Saved: ' + str(path)}
    raise ValueError('Unknown QR action')
