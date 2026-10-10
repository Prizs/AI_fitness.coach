
import urllib.request, re
def find_gymvisual(query):
    url = f'https://gymvisual.com/search?controller=search&s={urllib.parse.quote(query)}'
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        html = urllib.request.urlopen(req).read().decode('utf-8')
        match = re.search(r'img src=\x22(https://gymvisual.com/img/p/.*?.gif)\x22', html)
        if match: return match.group(1)
    except: pass
    return None

def download(name, url):
    if url:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with open(f'backend/app/static/{name}.gif', 'wb') as f:
            f.write(urllib.request.urlopen(req).read())
        print(f'Downloaded {name}')

download('press', find_gymvisual('standing military press'))
download('deadlift', find_gymvisual('barbell deadlift'))
download('pullup', find_gymvisual('pull up'))

