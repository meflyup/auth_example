library authentication;

import 'dart:io';

import 'package:redstone/server.dart' as app;
import 'package:mongo_dart/mongo_dart.dart';

import 'authorization.dart';
import 'utils.dart';

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
        
        Set roles = new Set();
        bool admin = user["admin"];
        if (admin != null && admin) {
          roles.add(ADMIN);
        }
        session["roles"] = roles;
        
        return {"success": true};
      });
}

@app.Route("/services/logout")
logout() {
  app.request.session.destroy();
  return {"success": true};
}