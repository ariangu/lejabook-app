curl -X POST "https://lejabook.com/oauth/token" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "password",
    "client_id": "4",
    "client_secret": "2LeYWVhDvQ8vMGf6TXM0JLmyXnHvx7CxqYBNMp0I",
    "username": "ariangu",
    "password": "iLoveLife@99$!"
  }' \
  -v

  curl -X POST "https://lejabook.com/oauth/token" \
  -H "Accept: application/json" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=4&client_secret=2LeYWVhDvQ8vMGf6TXM0JLmyXnHvx7CxqYBNMp0I&username=ariangu&password=iLoveLife%4099%24%21" \
  -v	


  curl -X POST "https://lejabook.com/oauth/token" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "password",
    "client_id": "4",
    "client_secret": "2LeYWVhDvQ8vMGf6TXM0JLmyXnHvx7CxqYBNMp0I",
    "username": "ariangu",
    "password": "iLoveLife@99$!"
  }' \
  -v

  ------------------------

  WRONG WAY

  curl -X POST "https://lejabook.com/oauth/token" \
  -H "Accept: application/json" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=password" \
  --data-urlencode "client_id=4" \
  --data-urlencode "client_secret=2LeYWVhDvQ8vMGf6TXM0JLmyXnHvx7CxqYBNMp0I" \
  --data-urlencode "username=ariangu" \
  --data-urlencode "password=iLoveLife@99$!" \
  -v