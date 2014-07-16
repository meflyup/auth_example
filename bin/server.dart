import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:redstone/server.dart' as app;
import 'package:crypto/crypto.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:connection_pool/connection_pool.dart';
import 'package:di/di.dart';
import 'package:shelf_static/shelf_static.dart';

class MongoDbPool extends ConnectionPool<Db> {

  String uri;

  MongoDbPool(String this.uri, int poolSize) : super(poolSize);

  @override
  void closeConnection(Db conn) {
    conn.close();
  }

  @override
  Future<Db> openNewConnection() {
    var conn = new Db(uri);
    return conn.open().then((_) => conn);
  }
}

@app.Interceptor(r'/services/.+')
dbManager(MongoDbPool pool) {
  pool.getConnection().then((managedConnection) {
    app.request.attributes["conn"] = managedConnection.conn;
    app.chain.next(() {
      if (app.chain.error is ConnectionException) {
        pool.releaseConnection(managedConnection, markAsInvalid: true);
      } else {
        pool.releaseConnection(managedConnection);
      }
    });
  });
}

@app.Interceptor(r'/services/private/.+')
authenticationFilter() {
  if (app.request.session["username"] == null) {
    app.chain.interrupt(statusCode: HttpStatus.UNAUTHORIZED, responseValue: {"error": "NOT_AUTHENTICATED"});
  } else {
    app.chain.next();
  }
}

@app.Route("/services/login", methods: const[app.POST])
login(@app.Attr() Db conn, @app.Body(app.JSON) Map body) {
  var userCollection = conn.collection("user");
  if (body["username"] == null || body["password"] == null) {
    return {"success": false, "error": "WRONG_USER_OR_PASSWORD"};
  }
  var pass = encryptPassword(body["password"].trim());
  return userCollection.findOne({"username": body["username"], "password": pass})
      .then((user) {
        if (user == null) {
          return {
            "success": false,
            "error": "WRONG_USER_OR_PASSWORD"
          };
        }
        
        var session = app.request.session;
        session["username"] = user["username"];
        session["admin"] = user["admin"];
        
        return {"success": true};
      });
}

@app.Route("/services/logout")
logout() {
  app.request.session.destroy();
  return {"success": true};
}

@app.Route("/services/newuser", methods: const[app.POST])
addUser(@app.Attr() Db conn, @app.Body(app.JSON) Map json) {
  
  String username = json["username"];
  String password = json["password"];
  
  username = username.trim();
  
  var userCollection = conn.collection("user");
  return userCollection.findOne({"username": username}).then((value) {
    if (value != null) {
      return {"success": false, "error": "USER_EXISTS"};
    }
    
    var user = {
      "username": username,
      "password": encryptPassword(password)
    };
    
    return userCollection.insert(user).then((resp) => {"success": true});
  });
}

String encryptPassword(String pass) {
  var toEncrypt = new SHA1();
  toEncrypt.add(UTF8.encode(pass));
  return CryptoUtils.bytesToHex(toEncrypt.close());
}

//private services

@app.Route("/services/private/echo/:arg")
echo(String arg) => arg;

main() {

  app.setupConsoleLog();
  app.setShelfHandler(createStaticHandler("web", 
                                          defaultDocument: "index.html", 
                                          serveFilesOutsidePath: true));

  var dbUri = "mongodb://localhost/auth_example";
  var poolSize = 3;

  app.addModule(new Module()
      ..bind(MongoDbPool, toValue: new MongoDbPool(dbUri, poolSize)));

  app.start();

}