import urllib.request
import urllib.error
import json

api_key = "AIzaSyCSKtnQJuxPWN6vdIKbyMVvQhs2ICDlX8g"
url = f"https://texttospeech.googleapis.com/v1/text:synthesize?key={api_key}"

data = {
    "input": {"text": "Click that dropdown that says No APIs"},
    "voice": {
        "languageCode": "en-US",
        "name": "en-US-Journey-F"
    },
    "audioConfig": {
        "audioEncoding": "MP3",
        "pitch": 0.0,
        "speakingRate": 1.0
    }
}

req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers={'Content-Type': 'application/json'})

try:
    with urllib.request.urlopen(req) as response:
        result = json.loads(response.read().decode('utf-8'))
        print("Success, received audio bytes length:", len(result.get('audioContent', '')))
except urllib.error.HTTPError as e:
    print(f"HTTP Error {e.code}: {e.read().decode('utf-8')}")
except Exception as e:
    print(f"Error: {e}")
