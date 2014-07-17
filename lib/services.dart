library services;

import 'package:redstone/server.dart' as app;
import 'package:mongo_dart/mongo_dart.dart';

import 'authorization.dart';
import 'utils.dart';

//A public service. Anyone can create a new user
@app.Route("/services/newuser", methods: const[app.POST])
addUser(@app.Attr() Db conn, @app.Body(app.JSON) Map json) {
  
  String username = json["username"];
  String password = json["password"];
  bool admin = json["admin"];
  
  username = username.trim();
  
  var userCollection = conn.collection("user");
  return userCollection.findOne({"username": username}).then((value) {
    if (value != null) {
      return {"success": false, "error": "USER_EXISTS"};
    }
    
    var user = {
      "username": username,
      "password": encryptPassword(password),
      "admin": admin
    };
    
    return userCollection.insert(user).then((resp) => {"success": true});
  });
}

//A private service. Any authenticated user can execute 'echo'
@app.Route("/services/private/echo/:arg")
echo(String arg) => arg;

//A private service. Only authenticated users with the 'ADMIN' role
//can view the list of registered users
@app.Route("/services/private/listusers")
@Secure(ADMIN)
listUsers(@app.Attr() Db conn) {
  
  var userCollection = conn.collection("user");
  return userCollection.find(where.excludeFields(const ["_id", "password"])).toList();
  
}