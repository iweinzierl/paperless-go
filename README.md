# Paperless-ngx App

This app is a frontend for the paperless-ngx document management system (https://github.com/paperless-ngx/paperless-ngx).
It gives users the possibility to connect to their paperless-ngx server by specifying the URL of the server together with
their username and password.


## Features

### Login page

The login page is the first UI shown to users after launching the app. It shows three text fields and a button to login. The text
fields allow users to enter the URL to their paperless-ngx server as well as their username and password required to authenticate
with the server.

### Home page

The home page shows two tabs: recent uploads and todos. The recent uploads tab is showing the 20 most recent uploaded documents
whereas the todos tab lists document that need a manuel verification.

### Documents page

The documents page lists documents which exists in the paperless-ngx server. It shows per default 20 documents. At the top of the page,
a search field allows users to search for specific documents. A click into the search field changes the UI. The user is able to enter
a search term which triggers a query to find documents which title's include the search term. This UI also offers drop down boxes to
filter for specific tags, correspondents and document types.


## Technology
* `flutter` framework is used so that Android and iOS clients can be built.
* `retrofit`is used for any network connection, e.g. to the paperless-ngx server.
* `Riverpod` is the brain and used for state management within the app.
* `shared_preferences` shall be used to store and manage user preferences (e.g. URL of the server, username, password).
* `Hive` will be used to cache data in the app to speed up app launches while loading server data in parallel.