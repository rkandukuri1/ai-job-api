import requests

url = "https://jsearch.p.rapidapi.com/search"
headers = {
    "X-RapidAPI-Key": "123fc79263mshbb6aa5a9b340d2ep14cba6jsn89bcce76b5c3",
    "X-RapidAPI-Host": "jsearch.p.rapidapi.com"
}

params = {
    "query": "Python developer",
    "page": 1,
    "num_pages": 1,
    "country": "us"
}

response = requests.get(url, headers=headers, params=params)

print(response.status_code)
print(response.text)