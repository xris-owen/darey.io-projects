## Web stack implementation (MEAN stack) in aws
---
This project shows a simple implementation of a web stack in aws.
Note: The EC2 instance is not created here. Steps to replicate one is shown on project1.
<br>

> ### **Step 1 - Install NodeJS**
Run the following command to install Node.js. NB: This automatically installs npm:

_Lets get the location of Node.js software from Ubuntu repositories._
```
# Update Ubuntu
$ sudo apt update

$ curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
```

Install Node.js with the command below

```
$ sudo apt-get install -y nodejs 
# run node -v and npm -v afterwards to check version of node and npm respectively.
```

> ### **Step 2: Install MongoDB**

1. Run the following command to install MongoDB:

```
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6

echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list

sudo apt install -y mongod
```
2. Start the mongodb server
```
sudo service mongodb start

sudo systemctl status mongodb
```

3. Install body-parser package. We need ‘body-parser’ package to help us process JSON files passed in requests to the server.
```
sudo npm install body-parser
```

4. Create a folder named ‘Books’, cd into it and initialize npm. 
```
mkdir Books && cd Books
npm init
```

5. Create a server.js file to run the server. Add the following code into the file:
```
var express = require('express');
var bodyParser = require('body-parser');
var app = express();
app.use(express.static(__dirname + '/public'));
app.use(bodyParser.json());
require('./apps/routes')(app);
app.set('port', 3300);
app.listen(app.get('port'), function() {
    console.log('Server up: http://localhost:' + app.get('port'));
});
```

> ### **Step 3 - Install Express and set up routes to the server**

1.  Run the following command to install Express and mongoose: <br> <br>Express is a minimal and flexible Node.js web application framework that provides features for web and mobile applications. <br> <br>We also will use Mongoose package which provides a straight-forward, schema-based solution to model your application data. We will use Mongoose to establish a schema for the database to store data of our book register.
```
npm install express mongoose
```
2. Make an apps directory and create a routes.js file in the folder to route requests. Add the following code into the file:

```
var Book = require('./models/book');
module.exports = function(app) {
  app.get('/book', function(req, res) {
    Book.find({}, function(err, result) {
      if ( err ) throw err;
      res.json(result);
    });
  }); 
  app.post('/book', function(req, res) {
    var book = new Book( {
      name:req.body.name,
      isbn:req.body.isbn,
      author:req.body.author,
      pages:req.body.pages
    });
    book.save(function(err, result) {
      if ( err ) throw err;
      res.json( {
        message:"Successfully added book",
        book:result
      });
    });
  });
  app.delete("/book/:isbn", function(req, res) {
    Book.findOneAndRemove(req.query, function(err, result) {
      if ( err ) throw err;
      res.json( {
        message: "Successfully deleted the book",
        book: result
      });
    });
  });
  var path = require('path');
  app.get('*', function(req, res) {
    res.sendfile(path.join(__dirname + '/public', 'index.html'));
  });
};
```

3. Make a models directory in the 'apps' folder and create a book.js file in the folder to define the schema for Book. Add the following code into the file:

```
var mongoose = require('mongoose');
var dbHost = 'mongodb://localhost:27017/test';
mongoose.connect(dbHost);
mongoose.connection;
mongoose.set('debug', true);
var bookSchema = mongoose.Schema( {
  name: String,
  isbn: {type: String, index: true},
  author: String,
  pages: Number
});
var Book = mongoose.model('Book', bookSchema);
module.exports = mongoose.model('Book', bookSchema);
```
> ### **Step 4 - Access the routes with AngularJS***

1. Cd to the root directory of the project and create a "public" directory. Create a "script.js" file in the "public" directory to load the AngularJS application. Add the following code into the file:

```
var app = angular.module('myApp', []);
app.controller('myCtrl', function($scope, $http) {
  $http( {
    method: 'GET',
    url: '/book'
  }).then(function successCallback(response) {
    $scope.books = response.data;
  }, function errorCallback(response) {
    console.log('Error: ' + response);
  });
  $scope.del_book = function(book) {
    $http( {
      method: 'DELETE',
      url: '/book/:isbn',
      params: {'isbn': book.isbn}
    }).then(function successCallback(response) {
      console.log(response);
    }, function errorCallback(response) {
      console.log('Error: ' + response);
    });
  };
  $scope.add_book = function() {
    var body = '{ "name": "' + $scope.Name + 
    '", "isbn": "' + $scope.Isbn +
    '", "author": "' + $scope.Author + 
    '", "pages": "' + $scope.Pages + '" }';
    $http({
      method: 'POST',
      url: '/book',
      data: body
    }).then(function successCallback(response) {
      console.log(response);
    }, function errorCallback(response) {
      console.log('Error: ' + response);
    });
  };
});
```
2. In public folder, create a file named index.html and paste the following code:
```
<!doctype html>
<html ng-app="myApp" ng-controller="myCtrl">
  <head>
    <script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.6.4/angular.min.js"></script>
    <script src="script.js"></script>
  </head>
  <body>
    <div>
      <table>
        <tr>
          <td>Name:</td>
          <td><input type="text" ng-model="Name"></td>
        </tr>
        <tr>
          <td>Isbn:</td>
          <td><input type="text" ng-model="Isbn"></td>
        </tr>
        <tr>
          <td>Author:</td>
          <td><input type="text" ng-model="Author"></td>
        </tr>
        <tr>
          <td>Pages:</td>
          <td><input type="number" ng-model="Pages"></td>
        </tr>
      </table>
      <button ng-click="add_book()">Add</button>
    </div>
    <hr>
    <div>
      <table>
        <tr>
          <th>Name</th>
          <th>Isbn</th>
          <th>Author</th>
          <th>Pages</th>

        </tr>
        <tr ng-repeat="book in books">
          <td>{{book.name}}</td>
          <td>{{book.isbn}}</td>
          <td>{{book.author}}</td>
          <td>{{book.pages}}</td>

          <td><input type="button" value="Delete" data-ng-click="del_book(book)"></td>
        </tr>
      </table>
    </div>
  </body>
</html>
```

3. cd back to books folder and start the server with the following command:
```
node server.js
```
4. Expose port 3300 in the EC2 instance inbound rules.

5. visit http://ip-address:3300/ in your browser. 

![Homepage](images/homepage.png)